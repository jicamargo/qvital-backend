# Plan de despliegue a producción

_Creado: 2026-09-24 · Estado: pendiente (no iniciado)_

Alcance: DB en Supabase (proyecto nuevo), backend Rails y frontend Next.js en proveedores por definir.

## Contexto clave

1. **Hay que desplegar también el backend Rails.** El frontend llama a `NEXT_PUBLIC_API_URL`, y Rails es quien habla con la DB, con los webhooks de Wompi y con Resend. Supabase solo aloja DB, Auth y Storage.
2. **El Supabase actual (`olpphsgcoxdljdbdnnph`) tiene datos de prueba** (ver `docs/database.md`). Recomendación: crear un **proyecto Supabase nuevo para producción** y dejar el actual como staging.
3. **`main` solo tiene el commit inicial.** Todo está en `develop`, y en ambos repos hay trabajo de la Brújula sin commitear (`feature/brujula-corporal-zonas`, `feature/brujula-peso-emociones`).

**Orden crítico:** Fase 1 → 2 (Supabase) → 3 (BE) → 4 (FE) → 5 (integraciones), porque el FE necesita la URL del BE y el BE la de la DB. Wompi va al final.

---

## Fase 0: Decisiones

| Decisión | Recomendación |
|---|---|
| Hosting del FE | **Vercel**: Next.js 16 nativo, cero configuración, preview por PR. Alternativas: Netlify o Cloudflare. |
| Hosting del BE | **Render o Railway** con el `Dockerfile` existente. Kamal (`config/deploy.yml`, hoy con placeholders) solo si se quiere un VPS propio. |
| Región | **us-east-1** para Supabase y para el BE (menor latencia hacia Colombia). DB y BE en la misma región. |
| Plan de Supabase | **Pro (US$25/mes)**. El plan gratis pausa el proyecto tras 7 días sin actividad y no tiene backups diarios. |
| Dominio | Por ejemplo `qvital.co` (FE) y `api.qvital.co` (BE). |
| Alcance del release | Decidir si la Brújula (sin commitear) entra o no. |

## Fase 1: Preparar el código

- [ ] Cerrar o commitear las features pendientes y mergearlas a `develop` (ambos repos).
- [ ] **`config/database.yml` de producción:** hoy apunta a 4 bases locales (`qvital_backend_production`, `_cache`, `_queue`, `_cable`), pero Supabase da una sola. Cambiar a `url: ENV["DATABASE_URL"]`.
  - Solid Queue: misma DB, cargando `db/queue_schema.rb` (hoy solo lo usa el `deliver_later` de `Marketplace::Orders::Complete`).
  - Cache: `memory_store` es suficiente por ahora.
  - Cable: quitarlo si no se usa.
- [ ] **Conexión a Supabase:** usar el **Session pooler** (`aws-0-<region>.pooler.supabase.com:5432`), porque la conexión directa es solo IPv6. Si se usa el Transaction pooler (6543), poner `prepared_statements: false`.
- [ ] **`config/environments/production.rb`:**
  - `action_mailer.default_url_options` hoy dice `example.com`; cambiarlo al dominio real.
  - Configurar `config.hosts`.
  - Revisar `active_storage.service = :local`: si algo usa ActiveStorage, se pierde en cada deploy.
- [ ] **CORS (`config/initializers/cors.rb`):** en producción, si `FRONTEND_URL` no existe, el valor por defecto es `"*"`. Definirla siempre.
- [ ] **Frontend, `next.config.ts`:** el hostname de Supabase está hardcodeado en `images.remotePatterns`. Agregar el del proyecto nuevo (o leerlo de una env var).
- [ ] `npm run build` limpio en el FE; `bin/rubocop` y `bin/brakeman` en el BE.
- [ ] Mergear `develop` → `main` en ambos repos. **Producción siempre se despliega desde `main`.**

## Fase 2: Supabase de producción

- [ ] Crear el proyecto en us-east-1, con un password de DB fuerte guardado en un gestor de contraseñas.
- [ ] Habilitar `unaccent` y `pg_trgm` en el schema `extensions` (los necesita la búsqueda full-text `spanish_unaccent`).
- [ ] **Schema:** no usar `db:schema:load`, porque `schema.rb` trae `create_schema "auth"`, `"vault"`, etc., que chocan con lo que Supabase ya crea. Dos opciones:
  - `bin/rails db:migrate` contra la DB nueva. Antes, probar que las migraciones corren limpias desde cero en una DB local vacía.
  - O `pg_dump --schema-only --schema=public` del proyecto actual + restaurar, junto con `schema_migrations`.
- [ ] **Datos:** solo el catálogo, sin usuarios ni órdenes de prueba: las 119 recetas, las zonas de la Brújula, productos, etc., con `db:seed` o un dump selectivo de tablas.
- [ ] **Storage:** crear los mismos buckets, copiar las imágenes y **reescribir los `image_url`** en la DB (hoy apuntan al host del proyecto viejo).
- [ ] **Seguridad (importante):** la Data API de Supabase expone las tablas de `public` con la anon key, que es pública en el FE. Como Rails se conecta como `postgres` y se salta RLS, **activar RLS sin políticas en todas las tablas de `public`**, o quitar `public` de los "Exposed schemas". Verificar que el Security Advisor quede en verde.
- [ ] **Auth:**
  - Site URL y Redirect URLs con el dominio de producción.
  - Plantillas de email en español.
  - **SMTP propio con Resend**: el SMTP por defecto de Supabase tiene un límite de pocos correos por hora.

## Fase 3: Backend

- [ ] Crear el servicio en Render/Railway desde el repo, rama `main`, con el Dockerfile.
- [ ] Variables de entorno:
  - `RAILS_MASTER_KEY`, `DATABASE_URL` (pooler), `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`
  - `FRONTEND_URL`, `ADMIN_NOTIFICATION_EMAIL`, `RESEND_API_KEY`, `SOLID_QUEUE_IN_PUMA=true`
  - Wompi de **producción**: `WOMPI_ENV`, `WOMPI_PUBLIC_KEY`, `WOMPI_PRIVATE_KEY`, `WOMPI_INTEGRITY_SECRET`, `WOMPI_EVENTS_SECRET`, `WOMPI_CHECKOUT_URL`, `WOMPI_API_BASE_URL`, `WOMPI_REDIRECT_URL`, `WOMPI_WEBHOOK_URL`
  - **`MARKETPLACE_MOCK_AUTO_APPROVE=false`**
- [ ] Release command: `bin/rails db:migrate`, para que cada deploy migre.
- [ ] Dominio `api.<dominio>` con SSL, y health check en `/up`.

## Fase 4: Frontend

- [ ] Importar el repo en Vercel (o el proveedor elegido), rama de producción `main`.
- [ ] Variables de entorno:
  - `NEXT_PUBLIC_API_URL` (la del BE de producción)
  - `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY` (del proyecto nuevo)
  - `NEXT_PUBLIC_APP_URL`, `NEXT_PUBLIC_WOMPI_CHECKOUT_URL`, `NEXT_PUBLIC_WOMPI_ENV`
- [ ] Ojo: las `NEXT_PUBLIC_*` quedan fijas en el build, así que cualquier cambio requiere un redeploy.
- [ ] Configurar el dominio.

## Fase 5: Integraciones externas

- [ ] **Wompi (producción):**
  - Webhook → la ruta de eventos del BE de producción.
  - Redirect → el dominio del FE.
  - Verificar el events secret.
- [ ] **Resend:** verificar el dominio (SPF, DKIM, DMARC) para que los correos no caigan en spam.
- [ ] **DNS:** registros del FE, del API y de email.

## Fase 6: Smoke test y go-live

- [ ] Signup y confirmación por email, login, logout y recuperar contraseña
- [ ] Dashboard, recetas (búsqueda con acentos, imágenes), Brújula, seguimiento
- [ ] Admin CRUD
- [ ] **Compra real de bajo monto con Wompi**: llega el webhook, la orden queda completada y sale el email al admin; después reembolsar
- [ ] Premium por compra, y los selects de dirección de Colombia
- [ ] Crear el usuario admin de producción y anunciar

## Fase 7: Después del lanzamiento

- [ ] Backups: confirmar los diarios de Supabase Pro (opcional: PITR).
- [ ] Monitoreo: Sentry en FE y BE, y uptime check de `/up`.
- [ ] **Staging:** Supabase actual + BE de staging + previews de Vercel desde `develop`.
- [ ] Actualizar `docs/database.md`: los dumps de producción tendrán usuarios reales, así que hay que **anonimizarlos** antes de bajarlos a local.

---

**Siguiente paso concreto:** elegir el hosting del BE y del FE (Fase 0), y luego empezar la Fase 1 en `feature/production-readiness` (branch desde `develop`).
