---
name: db-connect
description: Switch which Postgres qvital-backend's development/test environment points at — Supabase (the remote "production" Postgres, used as real data source) or Local (native Postgres on this machine, qvital_development/qvital_test). Edits qvital-backend/.env, toggling the DATABASE_URL line inside the "#### CONEXION SUPABASE" block (commented = local mode, uncommented = supabase mode) — nothing else in .env changes. Also supports a read-only "check" mode that reports which one is currently active without changing anything. Use when Jorge says things like "conéctame a Supabase", "cambia a mi base local", "conéctame a local", "¿a dónde estoy conectado?", "verifica la conexión de base de datos", or runs `/db-connect supabase|local|check`.
---

# db-connect

Switches `qvital-backend`'s `development`/`test` Rails environment between two Postgres targets, by toggling a single line in `.env`.

## Background (read this before editing anything)

- `config/database.yml`'s `development`/`test` blocks hardcode `database: qvital_development` / `qvital_test` and `host: 127.0.0.1`.
- Rails automatically applies **any environment variable literally named `DATABASE_URL`** to whichever `RAILS_ENV` is active, and this override takes priority over the explicit `host`/`database` in `database.yml` — confirmed empirically in this project (see `docs/database.md`).
- So the entire local/Supabase toggle is just: is `DATABASE_URL` set (via `.env`) or not.
- `.env` keeps the real Supabase connection string in `SUPABASE_DATABASE_URL` (always active — also used for `pg_dump`/`pg_restore`, see `docs/database.md`), and the `.env` line `DATABASE_URL=${SUPABASE_DATABASE_URL}` (dotenv variable interpolation) lives inside a block marked `#### CONEXION SUPABASE`. A block marked `#### CONEXION LOCALHOST` below it documents the local mode (no variables of its own — local mode is simply that `DATABASE_URL` line being commented out).
- `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` (Auth JWKS + Storage) are **not** part of this toggle — they stay active in both modes.

## Step 0 — figure out which mode

Parse the skill's `args`:
- `supabase` → target = supabase
- `local` → target = local
- `check` (or no recognizable argument) → if the user's message already clearly implies a target ("conéctame a mi base local", "cambia a supabase"), use that. Otherwise, if truly ambiguous, ask with AskUserQuestion: "¿A qué base quieres conectarte?" with options Local (recomendado para desarrollo diario), Supabase (datos reales remotos), Solo revisar (check).

## Step 1 — read current state

Read `qvital-backend/.env` and find the line inside the `#### CONEXION SUPABASE` block:
- `DATABASE_URL=${SUPABASE_DATABASE_URL}` (uncommented) → currently in **supabase** mode.
- `# DATABASE_URL=${SUPABASE_DATABASE_URL}` (commented) → currently in **local** mode.

## Step 2 — act based on target

### check
Report the current mode from Step 1, and confirm it empirically (don't just trust the comment state) by running:
```bash
cd qvital-backend && bin/rails runner "puts ActiveRecord::Base.connection_db_config.configuration_hash.slice(:host, :database, :adapter)"
```
- `host` = `aws-0-us-west-2.pooler.supabase.com` → Supabase.
- `host` = `127.0.0.1`, `database` = `qvital_development` (or `qvital_test` if `RAILS_ENV=test`) → Local.

Report both (the `.env` comment state and the live-resolved host/database) — if they disagree, say so explicitly rather than picking one silently.

Do not edit anything in check mode.

### supabase
Using Edit, uncomment the line (only if it's currently commented):
```
# DATABASE_URL=${SUPABASE_DATABASE_URL}
```
→
```
DATABASE_URL=${SUPABASE_DATABASE_URL}
```
Then run the same `bin/rails runner` snippet from Step 2/check to confirm it now resolves to the Supabase host, and tell Jorge:
- development/test now hit the real Supabase Postgres directly — any writes are real (this DB is also what `docs/database.md`'s dump/restore reads from).
- Remind him to switch back to `local` when done with whatever needed real Supabase data, to avoid accidentally running tests or scripts against the remote DB.

### local
Using Edit, comment the line (only if it's currently uncommented):
```
DATABASE_URL=${SUPABASE_DATABASE_URL}
```
→
```
# DATABASE_URL=${SUPABASE_DATABASE_URL}
```
Then run the same `bin/rails runner` snippet to confirm it now resolves to `127.0.0.1` / `qvital_development` (or `qvital_test`).

If Jorge wants fresh data in the local DBs at this point, point him at `docs/database.md`'s dump/restore commands rather than doing it automatically here (that's a heavier, explicit operation).

## Step 3 — always report the final state

One or two sentences: which mode is now active for `development`/`test`, confirmed via the live `connection_db_config` check, not just the `.env` comment.
