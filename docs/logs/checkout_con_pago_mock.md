

Started POST "/api/v1/marketplace/orders/prepare" for ::1 at 2026-03-05 07:50:59 -0500
Processing by Api::V1::Marketplace::OrdersController#prepare as */*
  Parameters: {"cart_items"=>[{"product_id"=>9, "quantity"=>3, "price"=>"104490.0", "metadata"=>{}}, {"product_id"=>7, "quantity"=>2, "price"=>"104490.0", "metadata"=>{}}], "shipping_address"=>{"street"=>"CR 5 SUR 83 200 CON RES LA FLORIDA 1", "city"=>"IBAGUE", "state"=>"Tolima", "zipCode"=>"730005", "phone"=>"3164695217"}, "recipient_info"=>{"is_different"=>false, "name"=>"", "phone"=>""}, "selected_date"=>"2026-03-05", "shipping_cost"=>"1000", "payment_method"=>"credit_card", "purchase_intent_id"=>nil, "order"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (174.9ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  TRANSACTION (174.7ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:89:in `find_or_initialize_purchase_intent'
  PurchaseIntent Create (348.4ms)  INSERT INTO "purchase_intents" ("user_id", "company_id", "external_reference", "status", "total_amount", "created_at", "updated_at") VALUES (1, NULL, '2e03f072-e3b8-4f69-8f73-44680f1e2ac9', 0, 523450.0, '2026-03-05 12:51:04.066655', '2026-03-05 12:51:04.066655') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:89:in `find_or_initialize_purchase_intent'
  Purchase Load (178.9ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 2 AND "purchases"."user_id" = 1 ORDER BY "purchases"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:104:in `find_or_initialize_purchase'
  PurchaseIntent Load (171.9ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 2 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:116:in `find_or_initialize_purchase'
  Purchase Create (171.9ms)  INSERT INTO "purchases" ("purchase_intent_id", "user_id", "company_id", "total_amount", "subtotal_amount", "tax_amount", "shipping_cost", "status", "purchase_number", "shipping_address", "recipient_name", "recipient_phone", "created_at", "updated_at") VALUES (2, 1, NULL, 523450.0, 522450.0, 0.0, 1000.0, 0, 'PUR-20260305125104-1', '{"street":"CR 5 SUR 83 200 CON RES LA FLORIDA 1","city":"IBAGUE","state":"Tolima","zipCode":"730005","phone":"3164695217"}', '', '', '2026-03-05 12:51:04.953299', '2026-03-05 12:51:04.953299') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:116:in `find_or_initialize_purchase'
  PurchaseItem Load (170.7ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 2 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:121:in `rebuild_purchase_items!'
  Product Load (182.3ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 9 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `block in rebuild_purchase_items!'
  PurchaseItem Create (170.8ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (2, 9, 3, 104490.0, 313470.0, 0.0, 313470.0, '{}', '2026-03-05 12:51:05.498209', '2026-03-05 12:51:05.498209') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `block in rebuild_purchase_items!'
  Product Load (170.5ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `block in rebuild_purchase_items!'
  PurchaseItem Create (173.1ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (2, 7, 2, 104490.0, 208980.0, 0.0, 208980.0, '{}', '2026-03-05 12:51:05.844355', '2026-03-05 12:51:05.844355') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `block in rebuild_purchase_items!'
  Order Load (172.7ms)  SELECT "orders".* FROM "orders" WHERE "orders"."purchase_id" = 2 ORDER BY "orders"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:144:in `find_or_initialize_order'
  Purchase Load (172.4ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 2 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:150:in `find_or_initialize_order'
  Order Create (174.9ms)  INSERT INTO "orders" ("purchase_id", "status", "total_amount", "shipping_date_estimated", "shipping_date_real", "tracking_info", "created_at", "updated_at") VALUES (2, 0, 523450.0, '2026-03-05 00:00:00', NULL, '{}', '2026-03-05 12:51:06.371656', '2026-03-05 12:51:06.371656') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:150:in `find_or_initialize_order'
  TRANSACTION (172.5ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:50:in `call'
  Category Load (176.4ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:81:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:81:in `serialize_prepare_result'
  OrderItem Load (170.8ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 2 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:85:in `serialize_prepare_result'
Completed 200 OK in 4351ms (Views: 0.2ms | ActiveRecord: 4685.2ms (16 queries, 1 cached) | GC: 1.5ms)


Started POST "/api/v1/marketplace/checkout/prepare" for ::1 at 2026-03-05 07:51:07 -0500
Processing by Api::V1::Marketplace::CheckoutController#prepare as */*
  Parameters: {"external_reference"=>"2e03f072-e3b8-4f69-8f73-44680f1e2ac9", "payer"=>{"name"=>"jicsoftware1@gmail.com", "email"=>"[FILTERED]", "phone"=>"3164695217", "document"=>""}, "order"=>{"amount"=>"523450.0", "currency"=>"COP", "provider"=>"mock_provider"}, "checkout"=>{"external_reference"=>"2e03f072-e3b8-4f69-8f73-44680f1e2ac9", "payer"=>{"name"=>"jicsoftware1@gmail.com", "email"=>"[FILTERED]", "phone"=>"3164695217", "document"=>""}, "order"=>{"amount"=>"523450.0", "currency"=>"COP", "provider"=>"mock_provider"}}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (172.8ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
Unpermitted parameter: :checkout. Context: { controller: Api::V1::Marketplace::CheckoutController, action: prepare, request: #<ActionDispatch::Request:0x0000777c99435980>, params: {"external_reference"=>"2e03f072-e3b8-4f69-8f73-44680f1e2ac9", "payer"=>{"name"=>"jicsoftware1@gmail.com", "email"=>"[FILTERED]", "phone"=>"3164695217", "document"=>""}, "order"=>{"amount"=>"523450.0", "currency"=>"COP", "provider"=>"mock_provider"}, "controller"=>"api/v1/marketplace/checkout", "action"=>"prepare", "checkout"=>{"external_reference"=>"2e03f072-e3b8-4f69-8f73-44680f1e2ac9", "payer"=>{"name"=>"jicsoftware1@gmail.com", "email"=>"[FILTERED]", "phone"=>"3164695217", "document"=>""}, "order"=>{"amount"=>"523450.0", "currency"=>"COP", "provider"=>"mock_provider"}}} }
  TRANSACTION (172.9ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  PurchaseIntent Load (343.5ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."external_reference" = '2e03f072-e3b8-4f69-8f73-44680f1e2ac9' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  Purchase Load (171.6ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 2 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:27:in `block in call'
  Payment Load (175.8ms)  SELECT "payments".* FROM "payments" WHERE "payments"."purchase_id" = 2 AND "payments"."external_reference" = '2e03f072-e3b8-4f69-8f73-44680f1e2ac9' AND "payments"."provider" = 'mock_provider' ORDER BY "payments"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:42:in `block in call'
  Purchase Load (174.5ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 2 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:53:in `block in call'
  Payment Create (181.3ms)  INSERT INTO "payments" ("purchase_id", "external_reference", "provider", "provider_payment_id", "provider_preference_id", "status", "amount", "currency", "raw_payload", "created_at", "updated_at") VALUES (2, '2e03f072-e3b8-4f69-8f73-44680f1e2ac9', 'mock_provider', NULL, 'a61245bc-8ca7-4369-9b85-d14301e8647e', 0, 523450.0, 'COP', '{"payer":{"name":"jicsoftware1@gmail.com","email":"jicsoftware1@gmail.com","phone":"3164695217","document":""},"order":{"amount":"523450.0","currency":"COP","provider":"mock_provider"}}', '2026-03-05 12:51:09.234510', '2026-03-05 12:51:09.234510') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:53:in `block in call'
  TRANSACTION (172.6ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:23:in `call'
Completed 200 OK in 2437ms (Views: 0.2ms | ActiveRecord: 1912.1ms (6 queries, 0 cached) | GC: 4.8ms)


Started POST "/api/v1/marketplace/orders/complete" for ::1 at 2026-03-05 07:51:09 -0500
Processing by Api::V1::Marketplace::OrdersController#complete as */*
  Parameters: {"purchase_id"=>2, "order_ids"=>[2], "cart_id"=>1, "order"=>{"purchase_id"=>2}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (175.7ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
Unpermitted parameter: :order. Context: { controller: Api::V1::Marketplace::OrdersController, action: complete, request: #<ActionDispatch::Request:0x0000777c99286238>, params: {"purchase_id"=>2, "order_ids"=>[2], "cart_id"=>1, "controller"=>"api/v1/marketplace/orders", "action"=>"complete", "order"=>{"purchase_id"=>2}} }
Unpermitted parameter: :order. Context: { controller: Api::V1::Marketplace::OrdersController, action: complete, request: #<ActionDispatch::Request:0x0000777c99286238>, params: {"purchase_id"=>2, "order_ids"=>[2], "cart_id"=>1, "controller"=>"api/v1/marketplace/orders", "action"=>"complete", "order"=>{"purchase_id"=>2}} }
Unpermitted parameter: :order. Context: { controller: Api::V1::Marketplace::OrdersController, action: complete, request: #<ActionDispatch::Request:0x0000777c99286238>, params: {"purchase_id"=>2, "order_ids"=>[2], "cart_id"=>1, "controller"=>"api/v1/marketplace/orders", "action"=>"complete", "order"=>{"purchase_id"=>2}} }
  TRANSACTION (175.0ms)  BEGIN /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Purchase Load (352.3ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 2 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Order Exists? (172.3ms)  SELECT 1 AS one FROM "orders" WHERE "orders"."id" = 2 AND "orders"."purchase_id" = 2 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:31:in `block in call'
  PurchaseIntent Load (170.6ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 2 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:33:in `block in call'
  PurchaseIntent Update (172.6ms)  UPDATE "purchase_intents" SET "status" = 1, "updated_at" = '2026-03-05 12:51:11.189978' WHERE "purchase_intents"."id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:34:in `block in call'
  Purchase Update (169.1ms)  UPDATE "purchases" SET "status" = 1, "updated_at" = '2026-03-05 12:51:11.365233' WHERE "purchases"."id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:37:in `block in call'
  Order Load (173.0ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 2 AND "orders"."purchase_id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:38:in `block in call'
  Order Update (170.0ms)  UPDATE "orders" SET "status" = 1, "updated_at" = '2026-03-05 12:51:11.711835' WHERE "orders"."id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:38:in `block (2 levels) in call'
  Cart Load (171.7ms)  SELECT "carts".* FROM "carts" WHERE "carts"."id" = 1 AND "carts"."user_id" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:58:in `complete_cart!'
  Cart Update (174.1ms)  UPDATE "carts" SET "status" = 1, "updated_at" = '2026-03-05 12:51:12.059534' WHERE "carts"."id" = 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:61:in `complete_cart!'
  TRANSACTION (173.8ms)  COMMIT /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:21:in `call'
  PurchaseItem Load (169.9ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:43:in `complete'
  Product Load (172.4ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 9 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:43:in `complete'
  Category Load (170.8ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:43:in `complete'
  Product Load (170.7ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:43:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:43:in `complete'
  OrderItem Load (170.2ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 2 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
Completed 200 OK in 3616ms (Views: 0.1ms | ActiveRecord: 3103.4ms (16 queries, 1 cached) | GC: 1.3ms)


Started GET "/api/v1/marketplace/cart" for ::1 at 2026-03-05 07:51:13 -0500
Processing by Api::V1::Marketplace::CartsController#show as */*
  Parameters: {"cart"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (175.0ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  Cart Load (177.0ms)  SELECT "carts".* FROM "carts" WHERE "carts"."user_id" = 1 AND "carts"."status" = 0 ORDER BY "carts"."created_at" DESC LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/marketplace/carts/fetch_open.rb:25:in `call'
Completed 200 OK in 1011ms (Views: 0.6ms | ActiveRecord: 351.9ms (2 queries, 0 cached) | GC: 0.3ms)


## Analisis del flujo (checkout con pago mock)

### Resultado general
- El flujo funcional completo se ejecuta exitosamente en este orden: `orders/prepare` -> `checkout/prepare` (mock) -> `orders/complete` -> `cart/show`.
- No hay errores 5xx en este log; todas las operaciones relevantes terminan en `200 OK`.
- Se evidencia manejo transaccional correcto en los puntos de escritura: hay `BEGIN`/`COMMIT` en `orders/prepare`, `checkout/prepare` y `orders/complete`.

### Hallazgos tecnicos
- **Transacciones y consistencia:** el backend usa transacciones en los 3 pasos criticos, por lo que ante excepciones en `save!`/`update!` deberia hacer rollback automaticamente.
- **Pago mock persistido:** en `checkout/prepare` se crea un registro en `payments` con `provider = mock_provider`, `provider_preference_id` generado y estado inicial `pending`.
- **Confirmacion de compra:** en `orders/complete` se confirma `purchase_intent`, `purchase`, `order` y se marca el `cart` como `completed`.
- **Ruido de strong params:** aparecen advertencias `Unpermitted parameter` para `:checkout` y `:order` (no rompen el flujo, pero contaminan logs y dificultan observabilidad).
- **Autenticacion repetitiva por request:** cada endpoint vuelve a hacer fetch/validacion JWKS y sincronizacion de metadata en Supabase; funcionalmente correcto, pero agrega latencia.
- **Latencia alta de DB:** la mayoria de queries estan alrededor de 170-350ms, lo que empuja tiempos totales altos (`~4.3s`, `~2.4s`, `~3.6s`) para un solo checkout.

### Riesgos funcionales a tener presentes (mientras siga el mock)
- El cierre de la orden se esta haciendo por llamada directa a `orders/complete` desde el frontend, no por confirmacion de pago aprobada via webhook.
- En un flujo real con Wompi/MercadoPago, confirmar orden sin estado `approved` del proveedor puede generar ordenes confirmadas sin pago validado.

### Recomendaciones
1. Mantener `orders/complete` como operacion de backend condicionada a pago aprobado (idealmente disparada por webhook verificado, no por cliente).
2. Para entorno mock, definir una regla explicita de negocio: `mock_auto_approve = true` (solo dev/staging), dejando trazabilidad de que es simulacion.
3. Limpiar `Unpermitted parameter` aceptando/normalizando el envelope enviado por frontend (`checkout`/`order`) para reducir ruido operativo.
4. Reducir latencia de autenticacion: cachear JWKS y evitar actualizar metadata de Supabase en cada request si no hubo cambios de rol.
5. Agregar pruebas de integracion para rollback transaccional en `prepare` y `complete` (fallo en `purchase_item`, `payment` u `order` debe revertir todo).
6. Cuando se integre proveedor real, validar firma del webhook, idempotencia por `provider_payment_id` y transicion de estados estricta (`pending -> approved/rejected`).

## Complemento: hallazgo sobre `order_items` no creados

### Observacion
- En el log de `orders/prepare` se crean correctamente `purchase_items` (2 inserts), pero no existe ningun `INSERT INTO order_items`.
- En la serializacion de respuesta aparece `OrderItem Load ... WHERE order_id = 2` y retorna vacio.
- En `orders/complete` tampoco se crean `order_items`; solo actualiza estados (`purchase_intent`, `purchase`, `order`, `cart`).

### Causa probable (segun flujo actual)
- El modelo `Order` tiene relacion `has_many :order_items`, pero el interactor `Marketplace::Orders::Prepare` solo reconstruye `purchase_items`.
- No hay un paso de mapeo `purchase_items -> order_items` ni en `prepare`, ni en `complete`, ni en `checkout/webhook`.
- Por eso en DB queda `orders` creado/confirmado, pero `order_items` vacio.

### Impacto funcional
- Se pierde el snapshot de lineas por orden en la entidad `order_items` (util para logistica, despacho, devoluciones y auditoria de orden).
- Cualquier proceso downstream que dependa de `order.order_items` (fulfillment, packing, tracking por item) no tendra datos.
- El frontend recibe `order_items: []`, lo cual puede ser coherente hoy, pero limita trazabilidad por orden.

### Recomendaciones especificas
1. Definir regla de negocio fuente de verdad:
   - persistir siempre `order_items` como snapshot operativo de la orden.
2. crear `order_items` en la misma transaccion de `orders/prepare`, inmediatamente despues de crear/reusar `order`.
3. Para idempotencia, usar estrategia `rebuild`: borrar `order.order_items` y recrear desde `purchase.purchase_items` en cada `prepare` del mismo `purchase_intent`.
4. Mantener consistencia monetaria: en `order_items.price` guardar `purchase_item.unit_price` y validar que suma de lineas coincida con `order.total_amount` (sin/ con shipping segun regla).
5. Agregar tests de integracion:
   - `prepare` crea `order_items` esperados.
   - nuevo `prepare` del mismo intent reemplaza lineas previas sin duplicar.
   - fallo al crear un `order_item` revierte toda la transaccion (sin `order` parcial).

## Implementacion aplicada (2026-03-05)

- Se implemento creacion de `order_items` dentro de la misma transaccion de `orders/prepare`, con estrategia `rebuild` (borra y recrea) para mantener idempotencia.
- Se agrego validacion de consistencia: subtotal de `order_items` debe coincidir con `purchase.subtotal_amount`; si falla, la transaccion revierte.
- Se condiciono `orders/complete` a pago aprobado (`payments.status = approved`).
- Para entorno mock se habilito regla configurable `MARKETPLACE_MOCK_AUTO_APPROVE` (por defecto `true` en development/staging): permite autoaprobar pagos `mock_provider` con trazabilidad en `raw_payload`.
- Se redujo ruido de `Unpermitted parameter` aceptando envelope `checkout` en `checkout/prepare` y `order` en `orders/complete`.
