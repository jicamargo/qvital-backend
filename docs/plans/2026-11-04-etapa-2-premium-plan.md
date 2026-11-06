# Etapa 2 Premium — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Premium acumula días, existe el "Plan Premium x 1 mes" (digital, sin dirección), un recordatorio diario con "Repetir mi último pedido", y correos útiles al admin (pedir en Herbalife) y a la clienta (pedido enviado).

**Architecture:** Backend Rails 8 API: reglas en interactors/POROs (`Premium::GrantForPurchase`, `Marketplace::Carts::RepeatLastOrder`), un job recurrente de Solid Queue y mailers. Frontend Next 16: utilidades puras probadas con vitest (`safeNextPath`, `isDigitalOnlyCart`, `buildCheckoutSchema`) y cambios de páginas.

**Tech Stack:** Rails 8.0, Minitest 6 (sin `Object#stub`, sin fixtures), Solid Queue, ActionMailer; Next.js 16, React 19, Zod, vitest.

**Spec:** `qvital-backend/docs/plans/2026-10-28-etapa-2-premium-diseno.md`

## Global Constraints

- Rama `feature/premium-etapa-2` en los dos repos; al terminar, merge `--no-ff` a `develop` y push.
- Backend: `RAILS_ENV=test bin/rails test` en verde antes de cada commit. Frontend: `npx tsc --noEmit -p .`, `npm test` y `npx eslint <archivos tocados>`.
- Frontend: `lib/services/auth.ts` y otros archivos CRLF se editan conservando CRLF (`newline=''` en Python); revisar con `file <ruta>` antes de editar.
- Textos para la clienta en español de Colombia, tuteo, frases cortas (público: mujeres mayores con poca experiencia en celular).
- Constantes: `Product::PREMIUM_PLAN_SKU = "QVITAL-PREMIUM-1M"`; plan: `premium_days: 30`, precio `30_000` en todos los niveles; `Premium::GrantForPurchase::THRESHOLD_DAYS = 30`; `PremiumReminderJob::WINDOW = 5.days`; recordatorio diario `at 9am every day` con zona `America/Bogota`; tope por producto `CartItem::MAX_QUANTITY` (10).
- Enlaces de correos: `ENV.fetch("FRONTEND_URL", "http://localhost:3010")`.
- Regla del `CLAUDE.md` del backend: todo endpoint nuevo o cambiado se documenta en `qvital-frontend/docs/endpoints/` y `db/schema.rb` se copia a `qvital-frontend/docs/schema.rb` (la ruta `/mnt/d/QVITAL/...` del CLAUDE.md es vieja: usar `~/qvital/qvital-frontend`).
- Un fallo al enviar correo nunca revierte ni hace fallar una compra o una actualización del admin (mismo patrón que `Complete#send_confirmation_email`).

## Review Focus

1. Usuaria con `premium_active: true` pero `premium_expires_at` vencido o `nil` → los días cuentan desde hoy, no desde la fecha vieja (Task 3).
2. "Repetir" con un producto que ya tiene 8 en el carrito y el pedido trae 5 → queda en 10 (tope), no falla todo (Task 5).
3. `next=//evil.com`, `next=https://evil.com` o `next=/\evil.com` → se ignora y va a `/` (Task 10).
4. Usuaria con `premium_active: false` y un `premium_expires_at` futuro no recibe recordatorio (Task 6).
5. Admin marca "enviado" una orden sin pago aprobado → se rechaza y no sale correo (Task 8).

---

## Backend (`qvital-backend`)

### Task 1: Columnas nuevas y producto digital

**Files:**
- Create: `db/migrate/20261104120000_add_premium_stage_two_columns.rb`
- Modify: `app/models/product.rb`, `app/blueprints/product_blueprint.rb`, `app/controllers/api/v1/admin/products_controller.rb` (permit), `app/interactors/admin/products/create.rb:42` y `update.rb` (slice)
- Test: `test/models/product_test.rb`, `test/controllers/api/v1/admin/products_controller_test.rb` (si existe; si no, en el test del interactor de create)

**Interfaces:**
- Produces: `products.premium_days` (integer, null), `users.premium_reminder_sent_for` (datetime, null), `orders.shipped_notified_at` (datetime, null); `Product::PREMIUM_PLAN_SKU`; `Product#digital? -> Boolean`; `Product.digital` / `Product.physical` scopes; `premium_days` en `ProductBlueprint` (vista default) y aceptado por admin create/update.

- [ ] **Step 1: Tests que fallan** — `Product#digital?` es true con `premium_days: 30`, false con nil; validación `premium_days` > 0 (0 inválido, nil válido); admin create con `premium_days: 30` lo guarda.
- [ ] **Step 2:** `RAILS_ENV=test bin/rails test test/models/product_test.rb` → FAIL (columna/método no existe).
- [ ] **Step 3:** Migración con las 3 columnas; `validates :premium_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true`; constante, método y scopes; blueprint y params.
- [ ] **Step 4:** `bin/rails db:migrate && RAILS_ENV=test bin/rails db:migrate && RAILS_ENV=test bin/rails test` → PASS.
- [ ] **Step 5:** Copiar `db/schema.rb` a `../qvital-frontend/docs/schema.rb`; anotar `premium_days` en `../qvital-frontend/docs/endpoints/` (productos y admin productos). Commit `feat(premium): add premium_days and stage-two columns`.

### Task 2: Plan Premium creado automáticamente

**Files:**
- Create: `db/migrate/20261104120100_create_premium_plan_product.rb`
- Modify: `db/seeds.rb`
- Test: `test/db/create_premium_plan_product_test.rb`

**Interfaces:**
- Consumes: `products.premium_days`, `Product::PREMIUM_PLAN_SKU` (Task 1).
- Produces: un producto `sku: QVITAL-PREMIUM-1M`, `name: "Plan Premium x 1 mes"`, `premium_days: 30`, `active: true`, `category_id: nil`, descripción corta en español, y `product_prices` de 30.000 para cada `Level`.

- [ ] **Step 1: Tests que fallan** (cargar la migración con `require Rails.root.join("db/migrate/20261104120100_create_premium_plan_product.rb")` y llamar `CreatePremiumPlanProduct.new.up`):
  - `test "creates the plan with a 30.000 price for every level"`: tras `up`, existe 1 producto con el SKU y `premium_days == 30`, y `ProductPrice.where(product:).count == Level.count` con precio 30_000.
  - `test "running it twice keeps a single plan"`: `up` dos veces → `Product.where(sku:).count == 1`.
  - `test "does not overwrite a price edited by the admin"`: `up`, cambiar un precio a 35_000, `up` → sigue en 35_000.
  - `test "adds a price for a level created later"`: `up`, crear un `Level` nuevo, `up` → ese nivel tiene precio 30_000.
- [ ] **Step 2:** Correr el test → FAIL (archivo no existe).
- [ ] **Step 3:** `up` con SQL propio (`execute`): `INSERT INTO products (...) VALUES (...) ON CONFLICT (sku) DO NOTHING` e `INSERT INTO product_prices (product_id, level_id, price, created_at, updated_at) SELECT ... FROM levels WHERE NOT EXISTS (...)`. `down`: no-op (no borra datos de negocio). Seed: `Product.find_or_create_by!(sku: Product::PREMIUM_PLAN_SKU) { ... }` + `find_or_create_by!` de precios por nivel.
- [ ] **Step 4:** Test → PASS; `bin/rails db:migrate` en desarrollo crea el plan; `bin/rails db:seed` no lo duplica.
- [ ] **Step 5:** Commit `feat(premium): create the Premium plan product idempotently`.

### Task 3: Días de Premium acumulados

**Files:**
- Create: `app/interactors/premium/grant_for_purchase.rb`
- Modify: `app/interactors/marketplace/orders/complete.rb` (reemplaza `grant_premium_if_qualifies!`; compra solo digital → órdenes `delivered`)
- Test: `test/interactors/premium/grant_for_purchase_test.rb`, `test/interactors/marketplace/orders/complete_test.rb`

**Interfaces:**
- Consumes: `Product#digital?`, `premium_days` (Task 1).
- Produces: `Premium::GrantForPurchase.call(purchase:, now: Time.current) -> Integer` (días otorgados; 0 si ninguno). Actualiza `user.premium_active`, `user.premium_expires_at`, `purchase.premium_granted`. `Premium::GrantForPurchase::THRESHOLD_DAYS = 30`.

- [ ] **Step 1: Tests que fallan** (umbral 200.000 vía `AppSetting.current`; `freeze_time`):
  - físicos 200.000, sin Premium → `premium_expires_at == now + 30.days`, retorna 30.
  - le quedan 5 días + físicos 200.000 → `now + 35.days`.
  - Premium vencido hace 3 días (`premium_active: true`) → `now + 30.days`.
  - `premium_expires_at: nil` → `now + 30.days`.
  - 1 plan + físicos 200.000 → 60 días; 2 planes solos → 60 días.
  - físicos 190.000 + plan 30.000 (total 220.000) → solo 30 días (el plan no cuenta para el umbral).
  - físicos 100.000 sin plan → retorna 0, `premium_expires_at` sin cambios, `premium_granted` false.
  - `complete_test`: compra solo con el plan → `order.delivered?`; compra mixta → `order.confirmed?`; llamar `Complete` dos veces no suma días dos veces.
- [ ] **Step 2:** Correr ambos tests → FAIL.
- [ ] **Step 3:** Días = (subtotal de ítems físicos ≥ umbral ? 30 : 0) + Σ(`premium_days` × cantidad de ítems digitales); base = `[now, premium_expires_at].compact.max`. Subtotal físico = suma de `purchase_items.line_subtotal` cuyo producto no es digital. En `Complete`, llamar dentro de la transacción y, si todos los ítems son digitales, `order.update!(status: :delivered)`.
- [ ] **Step 4:** Suite completa → PASS.
- [ ] **Step 5:** Commit `feat(premium): stack premium days and support the Premium plan`.

### Task 4: Checkout sin dirección para carrito solo digital

**Files:**
- Modify: `app/interactors/marketplace/orders/prepare.rb` (`call`: validar dirección solo si hay físicos)
- Test: `test/interactors/marketplace/orders/prepare_test.rb`

**Interfaces:**
- Consumes: `Product#digital?` (Task 1).
- Produces: `Prepare` acepta `shipping_address: { phone: "..." }` sin calle/ciudad si el carrito es solo digital; exige `recipient_info[:name]` y teléfono (`shipping_address[:phone]`) con los mensajes "Ingresa tu nombre." y "Ingresa un teléfono de contacto.".

- [ ] **Step 1: Tests que fallan:** carrito solo plan + `{ phone: "3000000000" }` → sin error; mismo carrito sin teléfono → error contiene "teléfono"; carrito mixto con dirección vacía → error de `AddressValidator` (como hoy).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Cargar el carrito antes de validar; `AddressValidator` solo si algún ítem es físico.
- [ ] **Step 4:** Suite → PASS. Actualizar `../qvital-frontend/docs/endpoints/` de `orders/prepare` (dirección opcional si solo digital).
- [ ] **Step 5:** Commit `feat(premium): digital-only checkout without shipping address`.

### Task 5: Repetir mi último pedido

**Files:**
- Create: `app/interactors/marketplace/carts/repeat_last_order.rb`, `app/controllers/api/v1/marketplace/carts_repeat_controller.rb`
- Modify: `config/routes.rb` (dentro de `resource :cart`: `post :repeat_last_order, to: "carts_repeat#create"`)
- Test: `test/interactors/marketplace/carts/repeat_last_order_test.rb`, `test/controllers/api/v1/marketplace/carts_repeat_controller_test.rb`

**Interfaces:**
- Produces: `Marketplace::Carts::RepeatLastOrder.call(user:)` → objeto con `cart`, `skipped` (Array<String> de nombres), `error`, `success?` (mismo estilo que `AddItem`). `POST /api/v1/marketplace/cart/repeat_last_order` → 200 `{ cart: <CartBlueprint>, skipped: [...] }`; 422 `{ error: "Aún no tienes pedidos para repetir." }`.

- [ ] **Step 1: Tests que fallan:**
  - suma los ítems de la última compra `confirmed` (no de una `pending` más nueva) al carrito abierto, con `price_snapshot` = precio actual del nivel.
  - carrito con 8 del producto + pedido con 5 → queda 10.
  - producto inactivo o sin precio para el nivel → omitido y su nombre en `skipped`.
  - sin compras confirmadas → `error == "Aún no tienes pedidos para repetir."`.
  - controller: 200 con `cart` y `skipped`; 422 sin compras (usar `stub_authenticated_as`).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implementar en una transacción; cantidad final = `[actual + pedida, CartItem::MAX_QUANTITY].min`; recargar con `Cart.with_marketplace_includes`.
- [ ] **Step 4:** Suite → PASS. Documentar el endpoint en `../qvital-frontend/docs/endpoints/`.
- [ ] **Step 5:** Commit `feat(premium): repeat last order into the cart`.

### Task 6: Recordatorio de vencimiento

**Files:**
- Create: `app/jobs/premium_reminder_job.rb`, `app/mailers/premium_mailer.rb`, `app/views/premium_mailer/reminder.html.erb`, `reminder.text.erb`, `test/mailers/previews/premium_mailer_preview.rb`
- Modify: `config/recurring.yml` (bloques `production` y `development`: `premium_reminder: { class: PremiumReminderJob, schedule: "at 9am every day America/Bogota" }`)
- Test: `test/jobs/premium_reminder_job_test.rb`, `test/mailers/premium_mailer_test.rb`

**Interfaces:**
- Consumes: `users.premium_reminder_sent_for` (Task 1), `Product::PREMIUM_PLAN_SKU` (Task 2).
- Produces: `PremiumReminderJob#perform` (sin argumentos); `PremiumMailer.reminder(user)`; asunto `"Tu Premium vence el #{I18n.l(fecha, format: '%-d de %B')}"` en español.

- [ ] **Step 1: Tests que fallan** (`ActionMailer::Base.deliveries`):
  - vence en 4 días → 1 correo y `premium_reminder_sent_for == premium_expires_at`.
  - vence en 6 días → ninguno.
  - ya vencido → ninguno.
  - `premium_active: false` y vence en 3 días → ninguno.
  - correr el job dos veces → 1 solo correo.
  - tras mover `premium_expires_at` 30 días y llegar a 4 días del nuevo → otro correo.
  - si el mailer lanza error para una usuaria, no se marca y las demás sí reciben.
  - mailer: con un último pedido con físicos, el cuerpo tiene "Repetir mi último pedido" y `/marketplace/repetir`; si el último pedido es solo digital (o no hay pedidos), el botón es "Comprar el Plan Premium" con enlace al producto del plan (`/marketplace/<id>`).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Consulta: `User.where(premium_active: true, premium_expires_at: now..(now + WINDOW)).where("premium_reminder_sent_for IS DISTINCT FROM premium_expires_at")`; por usuaria `deliver_now` en `begin/rescue` (log y seguir). Correo: saludo con nombre (`displayFirstName` del backend o `name.split.first`, "Hola" si no hay), beneficios (Brújula Corporal, Mi Plan, recetas), lista de productos del último pedido confirmado, botón principal, enlace secundario al plan.
- [ ] **Step 4:** Suite → PASS; abrir `http://localhost:3011/rails/mailers/premium_mailer/reminder`.
- [ ] **Step 5:** Commit `feat(premium): daily premium expiry reminder email`.

### Task 7: Correo al admin para pedir en Herbalife

**Files:**
- Modify: `app/views/order_mailer/admin_notification.text.erb`, `admin_notification.html.erb`, `app/mailers/order_mailer.rb#admin_notification` (asunto)
- Test: `test/mailers/order_mailer_test.rb`

**Interfaces:**
- Consumes: `Product#digital?` (Task 1).

- [ ] **Step 1: Tests que fallan:** compra mixta → cuerpo incluye `"<sku> · <nombre> · <sabor> · x<cantidad>"` solo de físicos, quién recibe y teléfono, cada parte de la dirección en su propia línea, el `provider_payment_id` del pago aprobado y `"#{FRONTEND_URL}/admin/orders/#{order.id}"`; compra solo digital → asunto termina en `"(Plan Premium, sin envío)"` y el cuerpo no contiene "Envío".
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Reescribir las dos vistas (no usar `_summary`, que sigue para el correo de la clienta). Sabor vacío se omite de la línea.
- [ ] **Step 4:** Suite → PASS; revisar en `/rails/mailers/order_mailer/admin_notification`.
- [ ] **Step 5:** Commit `feat(orders): actionable admin order email`.

### Task 8: Correo "¡Tu pedido va en camino!"

**Files:**
- Modify: `app/interactors/admin/orders/update.rb` (`normalize_tracking`, envío del correo), `app/mailers/order_mailer.rb` (`shipped(order)`)
- Create: `app/views/order_mailer/shipped.html.erb`, `shipped.text.erb`; preview en `test/mailers/previews/order_mailer_preview.rb`
- Test: `test/interactors/admin/orders/update_test.rb`, `test/mailers/order_mailer_test.rb`

**Interfaces:**
- Consumes: `orders.shipped_notified_at` (Task 1).
- Produces: `tracking_info` solo con `carrier`, `tracking_number`, `tracking_url` (strings; `tracking_url` se descarta si no es `http`/`https`); `OrderMailer.shipped(order)` con asunto `"¡Tu pedido #{purchase_number} va en camino!"`.

- [ ] **Step 1: Tests que fallan** (`include ActionMailer::TestHelper`):
  - pasar a `shipped` con pago aprobado → `assert_enqueued_emails 1` y `shipped_notified_at` presente.
  - guardar otra vez en `shipped` o cambiar la guía → `assert_no_enqueued_emails`.
  - orden sin pago aprobado → error y sin correo.
  - `tracking_info: { carrier: "Servientrega", tracking_number: "123", tracking_url: "javascript:alert(1)", extra: "x" }` → guarda solo carrier y número.
  - mailer: con guía muestra transportadora, número y "Rastrear mi pedido" si hay enlace; sin guía contiene "pronto te compartimos el número de guía"; incluye `/marketplace/orders/<id>`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Tras `@order.save`, si `@order.shipped? && @order.shipped_notified_at.nil?` → `update_column(:shipped_notified_at, Time.current)` y `OrderMailer.shipped(@order).deliver_later` en `begin/rescue`.
- [ ] **Step 4:** Suite → PASS. Documentar el formato de `tracking_info` en `../qvital-frontend/docs/endpoints/` de admin orders.
- [ ] **Step 5:** Commit `feat(orders): email the customer when an order ships`.

---

## Frontend (`qvital-frontend`)

### Task 9: Tipos y utilidades de producto digital

**Files:**
- Modify: tipos de producto en `lib/services/products.ts` / `marketplaceCart.ts` (agregar `premium_days?: number | null`)
- Create: `lib/utils/digitalProducts.ts`, `lib/utils/digitalProducts.test.ts`

**Interfaces:**
- Produces: `isDigitalProduct(p: { premium_days?: number | null } | null | undefined): boolean`; `isDigitalOnlyCart(items: Array<{ product?: { premium_days?: number | null } | null }>): boolean` (false con carrito vacío).

- [ ] **Step 1:** Tests: plan → true; `null`/`undefined`/0 → false; carrito con solo planes → true; mixto → false; vacío → false.
- [ ] **Step 2:** `npx vitest run lib/utils/digitalProducts.test.ts` → FAIL.
- [ ] **Step 3:** Implementar.
- [ ] **Step 4:** PASS + `tsc`.
- [ ] **Step 5:** Commit `feat(premium): digital product helpers`.

### Task 10: Volver a la página original después de iniciar sesión

**Files:**
- Create: `lib/utils/safeNextPath.ts`, `lib/utils/safeNextPath.test.ts`
- Modify: `components/auth/ProtectedRoute.tsx` (CRLF), `components/auth/LoginForm.tsx`, `components/auth/SignupForm.tsx`

**Interfaces:**
- Produces: `safeNextPath(raw: string | null | undefined, fallback = '/'): string`.

- [ ] **Step 1:** Tests: `'/marketplace/repetir'` → igual; `'/marketplace/orders?x=1'` → igual; `null`, `''`, `'//evil.com'`, `'https://evil.com'`, `'/\\evil.com'`, `'javascript:alert(1)'` → `'/'`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** `ProtectedRoute` redirige a `` `${redirectTo}?next=${encodeURIComponent(pathname + search)}` ``; `LoginForm` y `SignupForm` (cuando hay sesión) hacen `router.push(safeNextPath(searchParams.get('next')))`. `useSearchParams` exige `<Suspense>` en `app/login/page.tsx` y `app/signup/page.tsx`. El enlace "Crear mi cuenta"/"Iniciar sesión" entre las dos páginas conserva `next`.
- [ ] **Step 4:** PASS + `tsc` + eslint.
- [ ] **Step 5:** Commit `feat(auth): return to the requested page after login`.

### Task 11: Checkout sin dirección para el plan

**Files:**
- Modify: `lib/utils/validations/checkoutSchema.ts`, `app/marketplace/checkout/page.tsx`, `lib/contexts/MarketplaceCheckoutContext.tsx` (si arma el payload)
- Test: `lib/utils/validations/checkoutSchema.test.ts`

**Interfaces:**
- Consumes: `isDigitalOnlyCart` (Task 9).
- Produces: `buildCheckoutSchema({ digitalOnly }: { digitalOnly: boolean })`; `checkoutFormSchema` queda como `buildCheckoutSchema({ digitalOnly: false })`. En modo digital solo se exigen `recipientInfo.name`, `recipientInfo.lastName`, `shippingAddress.phone` y el aviso médico; `selectedDate` es opcional.

- [ ] **Step 1:** Tests: modo digital válido sin calle/ciudad/departamento/código postal; modo digital sin teléfono → error "Ingresa un teléfono de contacto"; modo normal sin calle → error "Ingresa la dirección".
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** La página calcula `digitalOnly` desde el carrito, oculta la sección de dirección y fecha, y muestra "Tu Plan Premium se activa apenas se apruebe el pago. No hay nada que enviar."
- [ ] **Step 4:** PASS + `tsc` + eslint.
- [ ] **Step 5:** Commit `feat(premium): checkout without address for the Premium plan`.

### Task 12: Repetir pedido en la app

**Files:**
- Modify: `lib/services/marketplaceCart.ts` (`repeatLastOrder()`), `lib/contexts/MarketplaceCartContext.tsx` (exponer la acción y actualizar el carrito), `app/marketplace/cart/page.tsx` (aviso de omitidos), `app/marketplace/orders/page.tsx` (botón)
- Create: `app/marketplace/repetir/page.tsx`

**Interfaces:**
- Consumes: `POST /api/v1/marketplace/cart/repeat_last_order` (Task 5).
- Produces: `repeatLastOrder(): Promise<{ cart: Cart; skipped: string[] }>` (lanza `Error` con el mensaje del backend en 422).

- [ ] **Step 1:** `/marketplace/repetir` (envuelta en `ProtectedRoute`): spinner "Preparando tu pedido…", llama a la acción y hace `router.replace('/marketplace/cart?omitidos=<n>')`; en error muestra el mensaje con botones "Ir al marketplace" y "Ver mis pedidos".
- [ ] **Step 2:** El carrito lee `omitidos` y muestra "N producto(s) de tu pedido anterior ya no están disponibles." (singular/plural).
- [ ] **Step 3:** "Mis pedidos": botón "Repetir este pedido" (enlace a `/marketplace/repetir`) solo en el pedido pagado más reciente.
- [ ] **Step 4:** `tsc` + eslint + `npm test`.
- [ ] **Step 5:** Commit `feat(premium): repeat last order page and buttons`.

### Task 13: Admin — días de Premium y seguimiento en 3 campos

**Files:**
- Modify: `app/admin/products/new/page.tsx`, `app/admin/products/[id]/edit/page.tsx` (campo "Días de Premium (solo para planes)", número opcional), servicio de admin productos (enviar `premium_days`), `app/admin/orders/[id]/page.tsx:409-416` (reemplaza el textarea JSON)

**Interfaces:**
- Consumes: `premium_days` en admin products (Task 1); `tracking_info` `{ carrier, tracking_number, tracking_url }` (Task 8).

- [ ] **Step 1:** Productos: input numérico vacío = `null`; valor > 0.
- [ ] **Step 2:** Orden: inputs "Transportadora", "Número de guía", "Enlace de rastreo (opcional)" que envían `tracking_info` con esas 3 claves; texto de ayuda bajo el estado: "Al guardar como Enviado, le llega un correo a la clienta (una sola vez)."
- [ ] **Step 3:** `tsc` + eslint.
- [ ] **Step 4:** Commit `feat(admin): premium days field and simple tracking form`.

### Task 14: Seguimiento en "Mis pedidos" y textos de `/premium`

**Files:**
- Modify: `app/marketplace/orders/[id]/page.tsx`, `app/premium/page.tsx`

- [ ] **Step 1:** Detalle del pedido: si hay `tracking_info.carrier`/`tracking_number`, mostrar "Transportadora", "Guía" y botón "Rastrear mi pedido" (`target="_blank" rel="noopener noreferrer"`) si hay `tracking_url`.
- [ ] **Step 2:** `/premium`: reemplazar los textos de "vuelve a durar 30 días desde esa compra" por "los días se suman a los que te quedan"; agregar "¿No vas a comprar productos este mes? Compra el Plan Premium por $30.000" con enlace al producto del plan (buscarlo por SKU `QVITAL-PREMIUM-1M` en el catálogo; si no está, ocultar el enlace).
- [ ] **Step 3:** `tsc` + eslint + `npm test`.
- [ ] **Step 4:** Commit `feat(premium): tracking in my orders and updated premium copy`.

---

### Task 15: Verificación de punta a punta y cierre

- [ ] **Step 1:** Backend `RAILS_ENV=test bin/rails test` y frontend `npm test` + `npx tsc --noEmit -p .` en verde; anotar los totales.
- [ ] **Step 2:** Navegador (viewport 390×844, cuenta `jicsoftware1+mariaprueba@gmail.com` / `123123`, Wompi sandbox 4242 4242 4242 4242):
  - comprar solo el Plan Premium: el checkout no pide dirección; tras pagar, `/premium` muestra +30 días y la orden queda "entregada".
  - con sesión cerrada, abrir `http://localhost:3010/marketplace/repetir` → login → vuelve y llena el carrito.
  - admin: marcar el pedido de prueba `PUR-20261026204015-3-C90E` como enviado con guía → el job de correo queda encolado una vez (revisar log o `SolidQueue::Job`).
  - correr `PremiumReminderJob.perform_now` en `bin/rails runner` con una usuaria a 4 días de vencer → revisar el preview del correo.
- [ ] **Step 3:** Marcar en `docs/plans/ruta-a-produccion.md` los ítems de la Etapa 2 con `_2026-11-04_` (y quitar "cédula" del ítem del correo al admin).
- [ ] **Step 4:** Merge `--no-ff` de `feature/premium-etapa-2` a `develop` en los dos repos y push.
