# Manejo de bases de datos — QVITAL Backend

## ¿Cuáles bases de datos hay?

| Ambiente | Motor | Dónde vive | Variable/config |
|----------|-------|------------|------------------|
| Producción real (Supabase) | Postgres 17 | Supabase (remoto) | `SUPABASE_DATABASE_URL` en `.env` |
| `development` (local) | Postgres 16 | Tu PC | `config/database.yml` → `qvital_development` |
| `test` (local) | Postgres 16 | Tu PC | `config/database.yml` → `qvital_test` |

Notas importantes:

- **No existe un ambiente de "staging" separado hoy.** Solo hay Supabase (llamado antes "producción" en el `.env", aunque la app aún no está deployada — sus datos son de prueba) y las dos bases locales.
- `development`/`test` corren en tu Postgres local (puerto 5432), conectando por **TCP a `127.0.0.1`** (no por socket Unix) porque esa ruta ya tiene auth `trust` sin password configurada en `pg_hba.conf`. No se tocó `pg_hba.conf` para no afectar otros proyectos que usás con DBeaver.
- Antes (hasta 2026-09-05) la variable se llamaba `DATABASE_URL`, y Rails la aplicaba automáticamente al ambiente activo — es decir, `development`/`test` estaban conectando sin querer directo a Supabase. Se renombró a `SUPABASE_DATABASE_URL` para evitar eso. Si en algún punto ven un comportamiento raro de "por qué mi dev está pegándole a producción", revisar que nadie haya vuelto a poner `DATABASE_URL` en `.env`.

## Cambiar entre Supabase y local (`/db-connect`)

`.env` tiene dos bloques marcados `#### CONEXION SUPABASE` y `#### CONEXION LOCALHOST`. Todo el switch es una sola línea dentro del bloque `CONEXION SUPABASE`:

```
# DATABASE_URL=${SUPABASE_DATABASE_URL}   ← comentada = modo local (default)
DATABASE_URL=${SUPABASE_DATABASE_URL}     ← descomentada = modo Supabase
```

En vez de editarlo a mano, usar el skill:

```
/db-connect local      # development/test → Postgres local (qvital_development/qvital_test)
/db-connect supabase   # development/test → Postgres remoto de Supabase (datos reales)
/db-connect check      # solo revisa y reporta a dónde está apuntando ahora mismo
```

`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` (Auth JWKS + Storage) no se tocan con esto — se quedan activos siempre, en ambos modos.

## Requisitos en tu máquina

- Postgres 16 corriendo local (`pg_lsclusters` para confirmar).
- Cliente `pg_dump`/`pg_restore` versión **17** (Supabase corre PG17, y el cliente debe ser igual o más nuevo que el servidor de origen). Si no lo tienes:
  ```bash
  sudo apt install -y postgresql-common
  sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
  sudo apt install -y postgresql-client-17
  ```
  Esto agrega el repo oficial de PostgreSQL e instala el cliente 17 sin tocar tu servidor local (que sigue en 16).

## Preparar el schema `extensions` (una sola vez por base)

Supabase instala `unaccent`/`pg_trgm` en un schema propio llamado `extensions` (no en `public`), y sus bases tienen ese schema agregado al `search_path` por defecto — por eso en Supabase `similarity(...)`, `unaccent(...)`, etc. funcionan sin calificar el schema. Replicar eso local es lo que deja pasar tanto el `CREATE TEXT SEARCH CONFIGURATION spanish_unaccent` que trae el dump como cualquier `search_by_text` (pg_search) sin tocar nada más:

```bash
for DB in qvital_development qvital_test; do
  psql -h 127.0.0.1 -U jicamargo -d "$DB" -v ON_ERROR_STOP=1 <<'SQL'
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS unaccent SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS pg_trgm SCHEMA extensions;
SQL
  psql -h 127.0.0.1 -U jicamargo -d "$DB" -c \
    "ALTER DATABASE $DB SET search_path TO \"\$user\", public, extensions;"
done
```

El `ALTER DATABASE ... SET search_path` solo aplica a conexiones nuevas — si tenías una consola/servidor Rails abierto, reinícialo después de correr esto.

Solo hace falta una vez por base (no en cada dump/restore), salvo que hayas creado la base de nuevo desde cero.

## Descargar una copia local de Supabase (dump + restore)

Con el paso anterior ya hecho:

1. Generar el dump (solo schema `public`, sin dueños/privilegios — esos no aplican local):
   ```bash
   set -a && source .env && set +a
   /usr/lib/postgresql/17/bin/pg_dump "$SUPABASE_DATABASE_URL" \
     --schema=public --no-owner --no-privileges -Fc -f /tmp/qvital_supabase_dump.dump
   ```
2. Restaurar en `development` y/o `test` (`--clean --if-exists` limpia lo que haya antes de cargar):
   ```bash
   /usr/lib/postgresql/17/bin/pg_restore -h 127.0.0.1 -U jicamargo -d qvital_development \
     --no-owner --no-privileges --clean --if-exists /tmp/qvital_supabase_dump.dump

   /usr/lib/postgresql/17/bin/pg_restore -h 127.0.0.1 -U jicamargo -d qvital_test \
     --no-owner --no-privileges --clean --if-exists /tmp/qvital_supabase_dump.dump
   ```
3. Vas a ver 1 error esperado en el output (no rompe nada): `unrecognized configuration parameter "transaction_timeout"` — parámetro exclusivo de PG17 que PG16 no reconoce, inofensivo.
4. Si restauraste `qvital_test`, corre `RAILS_ENV=test bin/rails db:environment:set RAILS_ENV=test` — el dump trae la fila de `ar_internal_metadata` tal cual estaba en Supabase, y Rails necesita que diga `test` en esa base para no quejarse de "environment mismatch" la próxima vez que corras algo con `RAILS_ENV=test`.

## Verificar que quedó todo bien

```bash
psql -h 127.0.0.1 -U jicamargo -d qvital_development -c "\dt"
psql -h 127.0.0.1 -U jicamargo -d qvital_development -c \
  "SELECT 'products', count(*) FROM products UNION ALL SELECT 'recipes', count(*) FROM recipes;"

bin/rails runner "puts ActiveRecord::Base.connection_db_config.configuration_hash.slice(:host, :database, :adapter)"
# development debe mostrar {:database=>"qvital_development", :adapter=>"postgresql"} (sin host de Supabase)
```

## Correr el test suite local

```bash
RAILS_ENV=test bin/rails test
```

Hay tests de controllers en `test/controllers/` (auth, products, categories, marketplace/carts, admin/products, evaluation_leads) que autentican simulando `Auth::SyncUser.call` (ver `test/test_helper.rb#stub_authenticated_as`) en vez de pegarle al JWKS real de Supabase — así corren offline. Usan `Level`/`Category` existentes (`find_or_create_by!`, igual que hace `db/seeds.rb`) y crean sus propios `User`/`Product` de prueba; cada test corre en una transacción que se revierte, así que no ensucian los datos reales restaurados en `qvital_test`.

**Importante:** `config/environments/test.rb` tiene `config.active_record.maintain_test_schema = false`. Sin eso, `bin/rails test` intenta "reparar" `qvital_test` recargando `db/schema.rb` completo — que declara schemas/extensiones exclusivos de Supabase (`vault.supabase_vault`, etc.) que no existen en Postgres local — y **purga la base** antes de fallar a mitad de camino. Si eso llegara a pasar (verías `db:test:load_schema` fallando y `qvital_test` con solo 2 tablas), no hay que arreglar el schema: solo repetir el dump/restore de arriba.

## Preguntas frecuentes

**¿Necesito anonimizar los datos del dump?**
No por ahora — la app no está deployada a producción, así que todo lo que hay en el Supabase actual son datos de prueba, no de usuarios reales. El día que haya datos reales de usuarios en Supabase, este proceso debe cambiar para anonimizar antes de bajar cualquier dump a una máquina local.

**¿Y las imágenes de productos/recetas (Supabase Storage)?**
Un `pg_dump` no las trae. Los campos `image_url`/`image_path` restaurados localmente siguen apuntando al bucket remoto de Supabase Storage (lectura pública), así que las imágenes se siguen viendo bien en local sin hacer nada extra.

**¿Por qué `127.0.0.1` y no `localhost` o el socket por defecto?**
Porque `pg_hba.conf` tiene reglas distintas para socket Unix (`local ... scram-sha-256`, pide password) vs. TCP a `127.0.0.1`/`::1` (`trust`, sin password). Usar `host: 127.0.0.1` en `database.yml` fuerza la ruta TCP y evita passwords en local, sin tocar la config del servidor Postgres.
