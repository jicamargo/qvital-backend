# Etapa 3 — Legal y privacidad: plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consentimiento expreso y probado para los datos de salud, textos legales, borrado de cuenta autoservicio, logs sin datos sensibles, límites de peticiones y verificación de que ninguna clienta ve datos de otra.

**Architecture:**

- **Backend:**
  - una tabla `consents`, a la que solo se agregan filas;
  - un `before_action` que bloquea con 403 a quien no tiene la versión vigente;
  - un interactor `Users::DeleteAccount`, compartido por la clienta y el admin, que borra los datos personales y anonimiza las compras.
- **Frontend:**
  - páginas legales estáticas con una versión;
  - casillas en el registro y en `/evaluacion`;
  - la pantalla `/antes-de-seguir`, a la que se llega desde `ProtectedRoute`;
  - la sección "Tus datos" en `/perfil`.

**Tech Stack:**

- Rails 8 API con Minitest (sin fixtures ni mocks de gema; ver `test/test_helper.rb`) y Rails 8 `rate_limit`.
- Next.js 16 con Vitest. Muchos archivos del FE usan CRLF: edítalos conservando los finales de línea.

**Spec:** `qvital-backend/docs/plans/2026-11-13-etapa-3-legal-diseno.md`. Léelo antes de cada tarea.

**Ramas:** `feature/etapa-3-legal` en los dos repos, saliendo de `develop`. Al terminar se hace merge `--no-ff` a `develop`, push y se borra la rama.

## Global Constraints

- **Versión legal:** `"2026-11-13"`. En el backend es `Consent::CURRENT_VERSION` y en el frontend `LEGAL_VERSION`, en `lib/legal.ts`.
- **Valores fijos:**
  - `kind`: `terms_and_health` | `marketing`;
  - `source`: `signup` | `gate` | `evaluacion` | `perfil`.
- **Copy exacto:**
  - casilla obligatoria: "Acepto los Términos y la Política de datos, y autorizo el uso de mis datos de salud (peso, medidas, cómo me siento) para darme recomendaciones.";
  - casilla opcional: "Quiero recibir consejos y promociones por correo o WhatsApp.";
  - error si falta la obligatoria: "Para crear tu cuenta necesitamos que aceptes esto.";
  - error de límite: "Demasiados intentos, espera un momento";
  - al borrar la cuenta: "Tu cuenta fue eliminada";
  - firma del pie: "Hecho por JIC Software".
- **Errores de la API:**
  - falta el consentimiento: 403 `{error: "consent_required"}`;
  - límite superado: 429;
  - consentimiento inválido: 422.
- **Datos pendientes:** se escriben literal como `[PENDIENTE: …]`. No se inventan.
- **Contrato con el frontend:** todo endpoint creado o cambiado actualiza `qvital-frontend/docs/endpoints/<archivo>.md`. Si cambia `db/schema.rb`, se copia a `qvital-frontend/docs/schema.rb`. Es regla de `CLAUDE.md`, pero la ruta real es `~/qvital/qvital-frontend`, no la de `/mnt/d` que dice ese archivo.
- **Usuarios:** son mujeres mayores con poca experiencia con el celular. Los controles van grandes (mínimo 44 px), tocables, y el texto es claro.
- **Pruebas:**
  - BE: `RAILS_ENV=test bin/rails test`;
  - FE: `npm test` y `npx tsc --noEmit`.

## Review Focus

1. **Clientas que ya existen y no tienen filas en `consents`:** deben ver la puerta y no pantallas rotas. Lo cubren la prueba de 403 en la Tarea B4 y la prueba de redirección en la Tarea F4.
2. **Borrar una cuenta con un carrito que tiene un `purchase_intent` apuntándole:** la FK no debe romper el borrado. Prueba en la Tarea B6.
3. **Volver a entrar después de borrar la cuenta** (falló el borrado en Supabase): se crea un usuario nuevo y vacío, y aparece la puerta. Prueba en la Tarea B6.
4. **Admin sin consentimiento:** debe seguir pudiendo usar `/api/v1/admin/*`. Prueba en la Tarea B4.
5. **Rate limit en el ambiente de pruebas:** el `cache_store` de test es `:null_store`, así que el límite nunca se activaría. La Tarea B8 usa un store propio, que las pruebas limpian.

---

## Backend (`qvital-backend`)

### Task B1: Modelo `Consent` y estado de consentimiento del usuario

**Files:**
- Create: `db/migrate/<ts>_create_consents.rb`, `app/models/consent.rb`, `test/models/consent_test.rb`
- Modify: `app/models/user.rb`, `app/models/evaluation_lead.rb`, `app/blueprints/user_blueprint.rb`, `test/test_helper.rb`, `db/schema.rb`

**Interfaces:**
- Produces:
  - `Consent::CURRENT_VERSION = "2026-11-13"`, `Consent::KINDS = %w[terms_and_health marketing]` y `Consent::SOURCES = %w[signup gate evaluacion perfil]`.
  - Asociaciones: `User has_many :consents, dependent: :delete_all` y `EvaluationLead has_many :consents, dependent: :delete_all`.
  - `User#consent_required? -> Boolean`: es verdadero si la última fila `terms_and_health` no existe, o tiene `granted: false`, o su `version` no es la vigente.
  - `User#marketing_opt_in? -> Boolean`: devuelve el `granted` de la última fila `marketing`, o `false`.
  - `UserBlueprint` agrega los campos `consent_required` y `marketing_opt_in`.
  - El helper de pruebas `grant_consent!(user)` crea una fila vigente `terms_and_health` con `source: "signup"`.
  - `stub_authenticated_as(user, consent: true)` llama a `grant_consent!` si `consent` es verdadero. Así las pruebas que ya existen no reciben 403 cuando llegue la Tarea B4.

- [ ] **Step 1: Escribir las pruebas que fallan** en `test/models/consent_test.rb`:
  - `"requires exactly one owner"`: sin `user` ni `evaluation_lead` → inválido; con los dos → inválido. Validación del modelo y, además, un check constraint en la DB.
  - `"rejects unknown kind and source"`.
  - `"consent_required? is true without rows, true for old version, false for current granted, true when last row is granted false"`.
  - `"marketing_opt_in? reflects the latest marketing row"`: `true` y después `false` → `false`.
- [ ] **Step 2: Correrlas y comprobar que fallan:** `RAILS_ENV=test bin/rails test test/models/consent_test.rb`. Debe fallar con `uninitialized constant Consent`.
- [ ] **Step 3: Implementar.**
  - **Migración** con las columnas de la tabla en la sección 2 del spec:
    - solo `created_at`, nada de `updated_at` (`t.datetime :created_at, null: false`);
    - las FK `user_id` y `evaluation_lead_id`;
    - el check `num_nonnulls(user_id, evaluation_lead_id) = 1`;
    - los índices `[user_id, kind, created_at]` y `[evaluation_lead_id]`.
  - **Modelo:** `self.record_timestamps` debe permitir que exista `created_at` sin `updated_at`. Se puede usar `before_create { self.created_at ||= Time.current }` con `record_timestamps = false`.
  - **Memoización:** `consent_required?` debe guardar el resultado por instancia, porque el bloqueo lo llama en cada request.
- [ ] **Step 4:** correr la prueba del modelo y la suite completa. Debe quedar todo en verde.
- [ ] **Step 5:** copiar `db/schema.rb` a `qvital-frontend/docs/schema.rb` (se hace commit en el repo del FE, Tarea F2) y hacer commit: `feat(consents): consent model and user consent state`.

### Task B2: `POST /api/v1/consents`

**Files:**
- Create: `app/interactors/consents/record.rb`, `app/controllers/api/v1/consents_controller.rb`, `test/interactors/consents/record_test.rb`, `test/controllers/api/v1/consents_controller_test.rb`, `qvital-frontend/docs/endpoints/api-v1-consents.md`
- Modify: `config/routes.rb` (`post "consents", to: "consents#create"`)

**Interfaces:**
- Consumes: la Tarea B1.
- Produces:
  - `Consents::Record.call(owner:, version:, source:, terms: nil, marketing: nil, ip_address: nil)`.
    - `owner` puede ser un `User` o un `EvaluationLead`.
    - Por cada valor no nil crea una fila: `terms` → `terms_and_health` y `marketing` → `marketing`.
    - Devuelve un resultado con `success?` y `error`.
    - Falla si la versión no es la vigente ("Versión de términos desactualizada"), si `source == "gate"` y `terms != true`, o si no viene ningún valor.
    - Todo dentro de una transacción.
  - `POST /consents {version, source, terms, marketing}`:
    - si sale bien, responde 201 `{consent_required:, marketing_opt_in:}`;
    - si falla, responde 422 `{error:}`.

- [ ] **Step 1: Escribir las pruebas que fallan.**
  - En el interactor:
    - `"records terms and marketing rows"`;
    - `"rejects old version"`;
    - `"gate requires terms true"`;
    - `"perfil can send only marketing"`, que crea 1 fila;
    - `"stores ip_address"`.
  - En el controlador, con `stub_authenticated_as(user, consent: false)`:
    - si sale bien → 201 y `consent_required == false`;
    - con versión vieja → 422.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3: Implementar.** El controlador hereda de `BaseController`, pasa `ip_address: request.remote_ip` y usa los parámetros permitidos `:version, :source, :terms, :marketing`. `terms` y `marketing` se convierten a booleano con `ActiveModel::Type::Boolean`, y se deja `nil` si no vienen.
- [ ] **Step 4:** correr las pruebas. Deben pasar.
- [ ] **Step 5:** escribir el doc del endpoint y hacer commit: `feat(consents): record consent endpoint`.

### Task B3: Registrar el consentimiento del signup en `auth/sync`

**Files:**
- Modify: `app/interactors/auth/sync_user.rb`, `test/controllers/api/v1/auth_controller_test.rb` (o un test nuevo del interactor), `qvital-frontend/docs/endpoints/` (doc de auth: la respuesta de `user` incluye los campos nuevos)

**Interfaces:**
- Consumes: `Consents::Record` de la Tarea B2.
- Produces: el frontend manda en el signup de Supabase `options.data = { consent_version, consent_marketing }`, y esos datos llegan en el JWT como `payload["user_metadata"]`.

- [ ] **Step 1: Escribir las pruebas que fallan.** Se extrae `sync_user(payload)` para poder probarlo sin JWKS: un método de clase `Auth::SyncUser.sync_from_payload(payload, ip_address: nil)` que `call` usa por dentro.
  - `"records signup consent from user_metadata when user has none"` → 2 filas con `source: "signup"`.
  - `"does not duplicate on second sync"`.
  - `"ignores metadata with old version"` → 0 filas, y `consent_required?` sigue en verdadero.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3: Implementar.** Después de `@user.save!`, si `user_metadata["consent_version"] == Consent::CURRENT_VERSION` y el usuario no tiene filas `terms_and_health`, llamar `Consents::Record` con `source: "signup", terms: true, marketing: user_metadata["consent_marketing"] == true`. Si falla, se registra en el log y el sync no falla.
- [ ] **Step 4:** correr las pruebas de auth y la suite completa. Deben pasar.
- [ ] **Step 5:** hacer commit: `feat(auth): record signup consent from supabase metadata`.

### Task B4: Bloqueo 403 `consent_required`

**Files:**
- Create: `app/controllers/concerns/requires_consent.rb`, `test/controllers/api/v1/consent_gate_test.rb`
- Modify: `app/controllers/api/v1/base_controller.rb`, `app/controllers/api/v1/settings_controller.rb`, `app/controllers/api/v1/consents_controller.rb`

**Interfaces:**
- Produces:
  - el `before_action :require_consent!`, que corre después de `authenticate_user!`;
  - para exentar un controlador: `skip_before_action :require_consent!`. Eso aplica a Settings (`show`), Consents y Users (`destroy_me`, de la Tarea B6);
  - el namespace admin queda exento dentro del concern con `return if controller_path.start_with?("api/v1/admin/")`.
  - `AuthController` no hereda de `BaseController`, así que ya queda exento.

- [ ] **Step 1: Escribir las pruebas que fallan** en `consent_gate_test.rb`, con `consent: false`:
  - `GET /api/v1/tracking` → 403 `{"error":"consent_required"}`;
  - `GET /api/v1/settings` → 200;
  - `POST /api/v1/consents` → 201;
  - un admin sin consentimiento en `GET /api/v1/admin/levels` → 200;
  - con `consent: true`, `GET /api/v1/tracking` → 200.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3:** implementar el concern e incluirlo en `BaseController`.
- [ ] **Step 4:** correr la suite completa. Debe quedar en verde, y la prueba de `DELETE /users/me` exento se agrega en la Tarea B6.
- [ ] **Step 5:** documentar el 403 en `api-v1-consents.md` y hacer commit: `feat(consents): block authenticated endpoints until consent`.

### Task B5: `/evaluation_leads` exige consentimiento

**Files:**
- Modify: `app/controllers/api/v1/evaluation_leads_controller.rb`, `app/interactors/evaluation_leads/create.rb`, `test/controllers/api/v1/evaluation_leads_controller_test.rb`, `qvital-frontend/docs/endpoints/api-v1-evaluation-leads.md`

**Interfaces:**
- Consumes: `Consents::Record` de la Tarea B2.
- Produces:
  - el cuerpo de la petición agrega `consent: {version, terms: true, marketing}`;
  - `EvaluationLeads::Create.call(params:, consent:, ip_address:)`;
  - sin `consent.terms == true` o con una versión vieja, responde 422 `{error: "Debes autorizar el uso de tus datos de salud"}`.

- [ ] **Step 1: Escribir las pruebas que fallan.**
  - `"rejects without consent"` → 422 y `EvaluationLead.count` sin cambio.
  - `"rejects old version"` → 422.
  - `"creates lead and consents"` → 201, con 2 filas `source: "evaluacion"` si `marketing` es verdadero.
  - Las pruebas actuales se actualizan para mandar `consent`.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3: Implementar.** El lead y sus filas se crean dentro de una transacción: si `Consents::Record` falla, se hace rollback.
- [ ] **Step 4:** correr las pruebas. Deben pasar.
- [ ] **Step 5:** actualizar el doc y hacer commit: `feat(evaluation-leads): require health data consent`.

### Task B6: Borrado de cuenta (`Users::DeleteAccount`)

**Files:**
- Create: `app/interactors/users/delete_account.rb`, `app/services/supabase/admin_users.rb`, `test/interactors/users/delete_account_test.rb`
- Modify: `app/interactors/admin/users/destroy.rb`, `app/controllers/api/v1/users_controller.rb`, `config/routes.rb` (`delete "users/me", to: "users#destroy_me"`), `test/controllers/api/v1/users_controller_test.rb`, `test/controllers/api/v1/admin/users_controller_test.rb`, `qvital-frontend/docs/endpoints/api-v1-users-me.md` y `api-v1-admin-users.md`

**Interfaces:**
- Produces:
  - `Users::DeleteAccount.call(user:)` devuelve un resultado con `success?` y `error`. Si el usuario es admin, devuelve el error "No se puede eliminar una cuenta de administrador".
  - `Supabase::AdminUsers.delete(supabase_uid) -> Boolean`. Hace `DELETE {SUPABASE_URL}/auth/v1/admin/users/{uid}` con la service role key, siguiendo el patrón HTTP de `Auth::UpdateSupabaseMetadata`. Si falla, registra el error y devuelve `false`.
  - `DELETE /api/v1/users/me`: responde 204 si sale bien y 422 `{error:}` si falla. Está exento del bloqueo de consentimiento.
  - `Admin::Users::Destroy` busca el usuario y delega en `DeleteAccount`. Se borra el rescue de `InvalidForeignKey`.

- [ ] **Step 1: Escribir las pruebas que fallan.** Para Supabase se reemplaza `Supabase::AdminUsers.delete` con `define_singleton_method`, igual que en `test_helper`.
  - `"deletes personal data"`: tracking, consulta y entradas, hábito y cumplimientos, feature usage, demo view, carrito e ítems, consents, y el `evaluation_lead` con su consent si tiene el mismo correo. Todo queda en `count 0` para ese usuario.
  - `"anonymizes purchases"`:
    - la compra sigue existiendo;
    - `user_id`, `recipient_name` y `recipient_phone` quedan nil;
    - `shipping_address == {}`;
    - `purchase_intent.user_id` y `cart_id` quedan nil;
    - el `raw_payload` del pago ya no tiene las claves `customer_email`, `customer_data`, `shipping_address` ni `billing_data`, buscadas en cualquier nivel (`data.transaction.*`), pero conserva `id`, `status`, `amount_in_cents` y `reference`.
  - `"deletes cart referenced by a purchase_intent"`: el caso 2 de Review Focus.
  - `"calls supabase delete after commit; failure still succeeds"`.
  - `"refuses admin"`.
  - En el controlador:
    - `DELETE /users/me` → 204 y `User.exists?` falso, incluso con `consent: false`.
    - Prueba del caso 3 de Review Focus: después del borrado, `Auth::SyncUser.sync_from_payload` con el mismo `sub` crea un usuario nuevo con `consent_required? == true`.
  - En el admin: borrar un usuario con compras → 200 y la compra queda anonimizada.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3: Implementar el interactor.**
  - Dentro de una transacción:
    1. anonimizar `purchases` e intents (incluido `cart_id: nil`) y limpiar `payments.raw_payload` con una función recursiva que quite esas 4 claves;
    2. `EvaluationLead.where(email: user.email).destroy_all`;
    3. borrar los carritos (`dependent` borra los ítems);
    4. `user.destroy!` (las asociaciones `dependent` borran el resto; agregar `has_many :carts, dependent: :destroy` si falta).
  - Después del commit, llamar `Supabase::AdminUsers.delete`, solo si hay `supabase_uid`.
- [ ] **Step 4:** correr las pruebas y la suite completa. Deben quedar en verde.
- [ ] **Step 5:** actualizar los docs y hacer commit: `feat(users): self-service account deletion with purchase anonymization`.

### Task B7: Logs sin datos sensibles y quitar `auth/update_metadata`

**Files:**
- Modify: `config/initializers/filter_parameter_logging.rb`, `app/controllers/api/v1/auth_controller.rb`, `config/routes.rb`, `CLAUDE.md` (route map y lista de endpoints de auth)
- Create: `test/config/filter_parameter_logging_test.rb`

- [ ] **Step 1: Escribir las pruebas que fallan.**
  - `"filters sensitive params"`: con `ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)`, cada uno de `weight_kg`, `waist_cm`, `height_cm`, `emotional_state`, `user_input`, `phone`, `recipient_phone`, `address`, `shipping_address`, `cedula`, `recipient_name`, `raw_payload` y `customer_data` debe salir como `"[FILTERED]"`, y `email` debe seguir filtrado.
  - `"update_metadata route is gone"`: `POST /api/v1/auth/update_metadata` → 404.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3: Implementar.** Agregar `:weight, :waist, :height, :emotional_state, :user_input, :phone, :address, :cedula, :recipient_name, :raw_payload, :customer_data` (el filtro de Rails hace coincidencia parcial). Borrar la acción, la ruta y la mención en `CLAUDE.md`. Revisar con `grep -rn "inspect" app/` que ningún log vuelque un payload de Wompi; hoy no hay ninguno.
- [ ] **Step 4:** correr las pruebas. Deben pasar.
- [ ] **Step 5:** hacer commit: `chore(security): filter sensitive params and remove debug endpoint`.

### Task B8: Límite de peticiones

**Files:**
- Create: `config/initializers/rate_limit_store.rb`, `test/controllers/api/v1/rate_limit_test.rb`
- Modify: `app/controllers/api/v1/evaluation_leads_controller.rb`, `app/controllers/api/v1/marketplace/checkout_controller.rb`, `app/controllers/api/v1/auth_controller.rb`, `app/controllers/api/v1/consents_controller.rb`, `app/controllers/api/v1/users_controller.rb`

**Interfaces:**
- Produces:
  - `RATE_LIMIT_STORE`: `ActiveSupport::Cache::MemoryStore.new` en test y `Rails.cache` en los demás ambientes. Las pruebas lo limpian en `setup` con `RATE_LIMIT_STORE.clear`.
  - En cada controlador: `rate_limit to:, within: 1.minute, only:, store: RATE_LIMIT_STORE, with: -> { render json: { error: "Demasiados intentos, espera un momento" }, status: :too_many_requests }`.
  - Límites:
    - `evaluation_leads#create`: 5;
    - `checkout#webhook`: 60;
    - `auth#sync`: 30;
    - `consents#create` y `users#destroy_me`: 10 cada uno.
  - Todos usan la IP por defecto.

- [ ] **Step 1: Escribir las pruebas que fallan.**
  - `"evaluation_leads: 6th request in a minute gets 429 with message"`.
  - `"consents: 11th gets 429"`.
  - El webhook, con 61 peticiones, solo valida el status 429 de la última; lleva una firma inválida, y eso no importa porque el límite corre antes.
- [ ] **Step 2:** correr las pruebas. Deben fallar.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr las pruebas y la suite completa. Deben quedar en verde.
- [ ] **Step 5:** documentar el 429 en los docs de los 5 endpoints y hacer commit: `feat(security): rate limit public and sensitive endpoints`.

### Task B9: Ninguna clienta ve datos de otra

**Files:**
- Create: `test/controllers/api/v1/cross_user_access_test.rb`
- Modify: lo que falle.

**Criterio:** la clienta B, autenticada, intenta leer o cambiar un recurso de la clienta A. Hoy algunas respuestas son 422 y no 404 (por ejemplo, Brújula "Consulta no encontrada" u orders complete). La prueba exige tres cosas:

- que la respuesta no sea 2xx;
- que el cuerpo no contenga el id ni ningún dato de A;
- que el recurso de A no cambie.

No se cambian los códigos 422 que ya existen a 404. Eso queda anotado como mejora si Jorge lo pide.

- [ ] **Step 1: Escribir una prueba por recurso.**
  - **Carrito:** `PATCH` y `DELETE /marketplace/cart/items/:id_de_A`.
  - **Pedidos:**
    - `GET /marketplace/orders` no lista los de A;
    - `POST orders/complete` con el `purchase_id` de A;
    - `GET checkout/status?external_reference=<de A>`.
  - **Seguimiento:** `GET /tracking` no trae las entradas de A.
  - **Hábitos:** `POST /habits/:id_de_A/toggle_completion` y `DELETE /habits/:id_de_A`.
  - **Brújula:** `GET /coach_virtual/consultations/:id_de_A`, `POST .../close`, `zone_selections`, `reflection_answers` y `practice_choices`.
  - **Perfil:** `PATCH /users/me` solo cambia a B.
- [ ] **Step 2:** correr las pruebas. Las que fallen son brechas reales: corregirlas buscando desde `current_user` en el interactor, con una prueba por corrección.
- [ ] **Step 3:** correr la suite completa. Debe quedar en verde.
- [ ] **Step 4:** hacer commit: `test(security): cross-user access checks`, más `fix(...)` por cada brecha corregida.

---

## Frontend (`qvital-frontend`)

### Task F1: Constantes legales, páginas legales y pie de página global

**Files:**
- Create:
  - `lib/legal.ts`;
  - `app/privacidad/page.tsx`, `app/terminos/page.tsx`, `app/aviso-de-salud/page.tsx`;
  - `components/legal/LegalPage.tsx` (layout con "En pocas palabras", el cuerpo y la versión y fecha al final);
  - `components/legal/HealthNotice.tsx` (aviso corto reutilizable, con enlace a `/aviso-de-salud`);
  - `components/layout/Footer.tsx`.
- Modify: `app/layout.tsx` (poner `<Footer />` después del `div.pb-24`).

**Interfaces:**
- Produces:
  - `export const LEGAL_VERSION = '2026-11-13'`;
  - `export const LEGAL_LINKS = { privacidad: '/privacidad', terminos: '/terminos', avisoSalud: '/aviso-de-salud' }`;
  - `<HealthNotice />`, sin props.

- [ ] **Step 1: Escribir las páginas** con el contenido de la sección 4 del spec. Ahí se dicen todos los puntos que cada página debe cubrir, en lenguaje claro y tuteando, y los `[PENDIENTE: …]` se copian literal.
  - Plazos de respuesta: 10 días hábiles para las consultas y 15 para los reclamos.
  - El texto del aviso de salud es el exacto del spec.
  - Son páginas públicas, sin `ProtectedRoute`, y se pueden prerenderizar como estáticas: sin `useSearchParams`.
- [ ] **Step 2: Escribir el pie de página:** "Política de datos · Términos · Aviso de salud", y en otra línea "Hecho por JIC Software". Texto mínimo de 16 px y enlaces con área de 44 px.
- [ ] **Step 3:** correr `npx tsc --noEmit && npm run build`. Las rutas `/privacidad`, `/terminos` y `/aviso-de-salud` deben aparecer como estáticas.
- [ ] **Step 4:** hacer commit: `feat(legal): legal pages, health notice and global footer`.

### Task F2: Tipos, servicio de consentimiento e interceptor del 403

**Files:**
- Create: `lib/services/consents.ts`, `lib/services/consentInterceptor.ts`, `lib/services/consentInterceptor.test.ts`
- Modify:
  - `lib/services/auth.ts`: agregar a `BackendUser` los campos `consent_required: boolean` y `marketing_opt_in: boolean`;
  - `lib/contexts/AuthContext.tsx`: instalar el interceptor una vez y, cuando se dispare, llamar `refreshUser()`;
  - `docs/schema.rb`: copia del backend, de la Tarea B1.

**Interfaces:**
- Produces:
  - `recordConsent({ source: 'gate' | 'perfil', terms?: boolean, marketing?: boolean }): Promise<{ consentRequired: boolean; marketingOptIn: boolean } | { error: string }>`. Siempre manda `version: LEGAL_VERSION`.
  - `isConsentRequiredResponse(response: Response): Promise<boolean>`. Devuelve `true` si el status es 403 y `(await response.clone().json()).error === 'consent_required'`. Si el JSON no se puede leer, devuelve `false`.
  - `installConsentInterceptor(apiUrl: string, onRequired: () => void): () => void`. Envuelve `window.fetch` solo para las URLs que empiezan con `apiUrl` y devuelve la función que deshace el cambio.

- [ ] **Step 1: Escribir las pruebas que fallan (Vitest).**
  - `isConsentRequiredResponse`: 403 con `consent_required` → `true`; 403 con otro error → `false`; 500 → `false`; un cuerpo que no es JSON → `false`.
  - `installConsentInterceptor`: llama `onRequired` con un 403 de la API, no lo llama con una URL externa y sigue devolviendo la respuesta original.
- [ ] **Step 2:** correr `npm test -- consentInterceptor`. Debe fallar.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** correr `npm test && npx tsc --noEmit`. Debe quedar en verde.
- [ ] **Step 5:** hacer commit: `feat(consents): consent service and 403 interceptor`.

### Task F3: Casillas en el registro

**Files:**
- Create: `components/legal/ConsentCheckboxes.tsx`, `components/legal/consentValidation.ts`, `components/legal/consentValidation.test.ts`
- Modify:
  - `components/auth/SignupForm.tsx`;
  - `lib/services/auth.ts`: `signUpWithEmail(email, password, consent: { marketing: boolean })` agrega a las opciones `data: { consent_version: LEGAL_VERSION, consent_marketing }`;
  - `lib/contexts/AuthContext.tsx`: `signUp` recibe y pasa `consent`.

**Interfaces:**
- Produces:
  - el componente `<ConsentCheckboxes terms={bool} marketing={bool} onTermsChange onMarketingChange termsError?: string variant?: 'signup' | 'evaluacion' />`. La variante `evaluacion` usa el texto adaptado del spec: "…autorizo el uso de estos datos de salud para darme mi resultado y recomendaciones";
  - `consentError(terms: boolean): string | null`, que devuelve "Para crear tu cuenta necesitamos que aceptes esto." o `null`.
  - Los enlaces "Términos" y "Política de datos", y "Leer más", abren en otra pestaña (`target="_blank" rel="noopener"`).

- [ ] **Step 1:** escribir la prueba de `consentError`. Debe fallar.
- [ ] **Step 2: Implementar.**
  - Las casillas son grandes: el área tocable es toda la fila, de mínimo 44 px.
  - `SignupForm` valida antes de llamar `signUp`. Si falta la obligatoria, muestra el error junto a la casilla y no la manda.
- [ ] **Step 3:** correr `npm test && npx tsc --noEmit`.
- [ ] **Step 4:** hacer commit: `feat(signup): consent checkboxes sent as supabase metadata`.

### Task F4: Pantalla "Antes de seguir"

**Files:**
- Create: `app/antes-de-seguir/page.tsx`, `lib/utils/consentGate.ts`, `lib/utils/consentGate.test.ts`
- Modify: `components/auth/ProtectedRoute.tsx`

**Interfaces:**
- Consumes: `recordConsent` (Tarea F2), `ConsentCheckboxes` (Tarea F3), y `useAuth().refreshUser` y `signOut`.
- Produces: `shouldRedirectToConsentGate(user: { consent_required: boolean } | null, pathname: string): boolean`. Es verdadero si hay usuario, `consent_required` es verdadero y la ruta no es `/antes-de-seguir`.

- [ ] **Step 1:** escribir las pruebas de `shouldRedirectToConsentGate`: sin usuario, con usuario que ya aceptó, con usuario que no ha aceptado en `/dashboard`, y en `/antes-de-seguir`. Deben fallar.
- [ ] **Step 2: Implementar.**
  - **`ProtectedRoute`:** hace `router.replace('/antes-de-seguir?next=…')` cuando corresponde y no muestra el contenido mientras redirige.
  - **La página:**
    - se protege con un guard propio, solo para la sesión, para no entrar en un ciclo;
    - usa `ConsentCheckboxes` en la variante `signup`, con el título "Antes de seguir" y una línea corta que diga que actualizamos los términos y necesitamos su autorización;
    - el botón "Aceptar y continuar" llama `recordConsent({source:'gate', terms:true, marketing})`, luego `refreshUser()`, y luego navega a `safeNextPath(next)`;
    - "Prefiero no aceptar: cerrar sesión" llama `signOut()` y lleva a `/`;
    - el enlace "Eliminar mi cuenta" abre el mismo modal de la Tarea F6, que se importa de ahí. Por eso F6 extrae ese modal como componente.
  - Lee `next` con `window.location.search` dentro de un efecto, no con `useSearchParams`.
- [ ] **Step 3:** correr `npm test && npx tsc --noEmit && npm run build`.
- [ ] **Step 4:** hacer commit: `feat(consents): before-you-continue gate`.

> **Orden:** haz la Tarea F6 antes del Step 2 de la F4, o crea en la F4 el componente `DeleteAccountDialog` que describe la F6 y en la F6 solo úsalo.

### Task F5: Casillas en `/evaluacion`

**Files:**
- Modify: `app/evaluacion/page.tsx`, `lib/services/evaluationLeads.ts`

**Interfaces:**
- Produces: `EvaluationLeadPayload` agrega `consent: { terms: true; marketing: boolean }`. El servicio manda `consent: { version: LEGAL_VERSION, terms, marketing }`.

- [ ] **Step 1: Implementar.**
  - El formulario del correo muestra `<ConsentCheckboxes variant="evaluacion" />` arriba del botón.
  - `handleSubmitEmail` usa `consentError(terms)`, con el mensaje propio de la evaluación: "Para guardar tu evaluación necesitamos que aceptes esto."
  - `<HealthNotice />` va al final de la página.
- [ ] **Step 2:** correr `npx tsc --noEmit && npm run build`.
- [ ] **Step 3:** hacer commit: `feat(evaluacion): health data consent and notice`.

### Task F6: `/perfil` "Tus datos" y borrado de cuenta

**Files:**
- Create: `components/perfil/YourDataCard.tsx`, `components/perfil/DeleteAccountDialog.tsx`
- Modify: `app/perfil/page.tsx` (poner la tarjeta antes de "Acciones"), `lib/services/userProfile.ts`

**Interfaces:**
- Produces:
  - `deleteMyAccount(): Promise<{ success: true } | { error: string }>`, que llama `DELETE /api/v1/users/me`;
  - `<DeleteAccountDialog open onClose />`. Si sale bien, hace `signOut()` y navega a `/?cuenta=eliminada`;
  - la portada (`app/page.tsx`) muestra el aviso "Tu cuenta fue eliminada" cuando viene `cuenta=eliminada`. Lo lee con `window.location.search` en un efecto.

- [ ] **Step 1: Implementar `YourDataCard`.**
  - Tiene el interruptor "Recibir consejos y promociones", con el valor inicial de `user.marketing_opt_in`. Al cambiarlo llama `recordConsent({source:'perfil', marketing})` y luego `refreshUser()`. Si falla, revierte el interruptor y muestra el error.
  - Tiene los enlaces a las tres páginas legales.
  - Dice "Para pedir una copia o corregir tus datos, escríbenos a `[PENDIENTE: correo]`".
  - Tiene el botón rojo "Eliminar mi cuenta".
- [ ] **Step 2: Implementar `DeleteAccountDialog`.**
  - El texto explica que se borran su seguimiento, sus consultas y sus hábitos; que "Tus compras se guardan sin tu nombre, por contabilidad"; y que no se puede deshacer.
  - Botón rojo grande "Sí, eliminar mi cuenta" y botón secundario "No, volver".
  - Mientras borra, muestra un spinner. Si falla, muestra el error dentro del modal.
- [ ] **Step 3:** correr `npx tsc --noEmit && npm run build`.
- [ ] **Step 4:** hacer commit: `feat(perfil): your data section and account deletion`.

### Task F7: Verificación en el navegador y cierre

- [ ] **Step 1:** levantar el BE (puerto 3011) y el FE (puerto 3010) con la DB local migrada.
- [ ] **Step 2: Recorrer con Chrome DevTools en un viewport móvil** (390×844), con el usuario `jicsoftware1+authux1028@gmail.com` y la contraseña 123123:
  1. sin consentimiento → llega a `/antes-de-seguir` → acepta → vuelve a la página pedida;
  2. el pie de página y las 3 páginas legales;
  3. `/evaluacion`: sin la casilla no guarda, con la casilla sí;
  4. en `/perfil`, apagar y prender el mercadeo;
  5. registro nuevo con las casillas, revisando las filas en `consents`;
  6. borrar la cuenta del usuario desechable y confirmar el aviso y que el usuario ya no está en la DB. Confirmar con Jorge antes de borrar en Supabase si la DB apunta a Supabase compartido.
- [ ] **Step 3:** correr la suite completa del BE y `npm test && npm run build` en el FE.
- [ ] **Step 4:** marcar los ítems de la Etapa 3 en `docs/plans/ruta-a-produccion.md`, con la fecha y los hashes de los commits. Hacer merge `--no-ff` a `develop` en los dos repos, push y borrar las ramas.
