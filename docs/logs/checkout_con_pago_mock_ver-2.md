FLUJO DE LA API AL HACER UN CHECKOUT CON PAGO MOCK


Started POST "/api/v1/marketplace/orders/prepare" for ::1 at 2026-03-05 09:50:06 -0500
Processing by Api::V1::Marketplace::OrdersController#prepare as */*
  Parameters: {"cart_items"=>[{"product_id"=>7, "quantity"=>1, "price"=>"104490.0", "metadata"=>{}}, {"product_id"=>19, "quantity"=>1, "price"=>"145250.0", "metadata"=>{}}, {"product_id"=>36, "quantity"=>1, "price"=>"224630.0", "metadata"=>{}}, {"product_id"=>34, "quantity"=>1, "price"=>"118570.0", "metadata"=>{}}, {"product_id"=>35, "quantity"=>2, "price"=>"110460.0", "metadata"=>{}}, {"product_id"=>29, "quantity"=>2, "price"=>"127030.0", "metadata"=>{}}], "shipping_address"=>{"street"=>"CON RES LA FLORIDA 1", "city"=>"LIBANO", "state"=>"Tolima", "zipCode"=>"730005", "phone"=>"8135518577"}, "recipient_info"=>{"is_different"=>false, "name"=>"JAIME CAMARGO ", "phone"=>"8135518577"}, "selected_date"=>"2026-03-06", "shipping_cost"=>"0", "payment_method"=>"credit_card", "purchase_intent_id"=>nil, "update_user_profile"=>true, "order"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (158.3ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  TRANSACTION (151.7ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:94:in `find_or_initialize_purchase_intent'
  PurchaseIntent Create (152.5ms)  INSERT INTO "purchase_intents" ("user_id", "company_id", "external_reference", "status", "total_amount", "created_at", "updated_at") VALUES (1, NULL, '91a18b9f-cbaa-437f-8ebe-5ea09ee31549', 0, 1067920.0, '2026-03-05 14:50:08.404124', '2026-03-05 14:50:08.404124') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:94:in `find_or_initialize_purchase_intent'
  Purchase Load (151.9ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 4 AND "purchases"."user_id" = 1 ORDER BY "purchases"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:109:in `find_or_initialize_purchase'
  PurchaseIntent Load (153.8ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 4 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:121:in `find_or_initialize_purchase'
  Purchase Create (151.9ms)  INSERT INTO "purchases" ("purchase_intent_id", "user_id", "company_id", "total_amount", "subtotal_amount", "tax_amount", "shipping_cost", "status", "purchase_number", "shipping_address", "recipient_name", "recipient_phone", "created_at", "updated_at") VALUES (4, 1, NULL, 1067920.0, 1067920.0, 0.0, 0.0, 0, 'PUR-20260305145009-1', '{"street":"CON RES LA FLORIDA 1","city":"LIBANO","state":"Tolima","zipCode":"730005","phone":"8135518577"}', 'JAIME CAMARGO ', '8135518577', '2026-03-05 14:50:09.200517', '2026-03-05 14:50:09.200517') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:121:in `find_or_initialize_purchase'
  PurchaseItem Load (151.8ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 4 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:126:in `rebuild_purchase_items!'
  Product Load (150.3ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (160.4ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 7, 1, 104490.0, 104490.0, 0.0, 104490.0, '{}', '2026-03-05 14:50:09.980375', '2026-03-05 14:50:09.980375') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Product Load (160.1ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (150.6ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 19, 1, 145250.0, 145250.0, 0.0, 145250.0, '{}', '2026-03-05 14:50:10.312487', '2026-03-05 14:50:10.312487') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Product Load (151.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 36 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (153.3ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 36, 1, 224630.0, 224630.0, 0.0, 224630.0, '{}', '2026-03-05 14:50:10.619413', '2026-03-05 14:50:10.619413') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Product Load (150.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 34 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (158.5ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 34, 1, 118570.0, 118570.0, 0.0, 118570.0, '{}', '2026-03-05 14:50:10.929134', '2026-03-05 14:50:10.929134') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Product Load (152.2ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 35 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (151.8ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 35, 2, 110460.0, 220920.0, 0.0, 220920.0, '{}', '2026-03-05 14:50:11.243443', '2026-03-05 14:50:11.243443') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Product Load (153.8ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 29 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  PurchaseItem Create (153.7ms)  INSERT INTO "purchase_items" ("purchase_id", "product_id", "quantity", "unit_price", "line_subtotal", "line_tax", "line_total", "metadata", "created_at", "updated_at") VALUES (4, 29, 2, 127030.0, 254060.0, 0.0, 254060.0, '{}', '2026-03-05 14:50:11.554359', '2026-03-05 14:50:11.554359') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:135:in `block in rebuild_purchase_items!'
  Order Load (150.7ms)  SELECT "orders".* FROM "orders" WHERE "orders"."purchase_id" = 4 ORDER BY "orders"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:149:in `find_or_initialize_order'
  Purchase Load (150.9ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 4 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:155:in `find_or_initialize_order'
  Order Create (150.7ms)  INSERT INTO "orders" ("purchase_id", "status", "total_amount", "shipping_date_estimated", "shipping_date_real", "tracking_info", "created_at", "updated_at") VALUES (4, 0, 1067920.0, '2026-03-06 00:00:00', NULL, '{}', '2026-03-05 14:50:12.174873', '2026-03-05 14:50:12.174873') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:155:in `find_or_initialize_order'
  OrderItem Load (152.2ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 4 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:160:in `rebuild_order_items!'
  Product Load (155.1ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (157.6ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 7, 1, 104490.0, '{}', '2026-03-05 14:50:12.956937', '2026-03-05 14:50:12.956937') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  Product Load (150.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (151.7ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 19, 1, 145250.0, '{}', '2026-03-05 14:50:13.270089', '2026-03-05 14:50:13.270089') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  Product Load (150.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 36 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (153.1ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 36, 1, 224630.0, '{}', '2026-03-05 14:50:13.578126', '2026-03-05 14:50:13.578126') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  Product Load (152.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 34 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (152.1ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 34, 1, 118570.0, '{}', '2026-03-05 14:50:13.888964', '2026-03-05 14:50:13.888964') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  Product Load (159.4ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 35 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (150.4ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 35, 2, 110460.0, '{}', '2026-03-05 14:50:14.207689', '2026-03-05 14:50:14.207689') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  Product Load (155.1ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 29 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  OrderItem Create (151.5ms)  INSERT INTO "order_items" ("order_id", "product_id", "quantity", "price", "metadata", "created_at", "updated_at") VALUES (4, 29, 2, 127030.0, '{}', '2026-03-05 14:50:14.519018', '2026-03-05 14:50:14.519018') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:163:in `block in rebuild_order_items!'
  User Update (151.1ms)  UPDATE "users" SET "updated_at" = '2026-03-05 14:50:14.673966', "phone" = '8135518577', "address" = '{"street":"CON RES LA FLORIDA 1","city":"LIBANO","state":"Tolima","zipCode":"730005","phone":"8135518577"}' WHERE "users"."id" = 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:201:in `update_user_profile_from_checkout!'
  TRANSACTION (154.2ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:52:in `call'
  Category Load (150.8ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  Category Load (153.1ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 4 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  Category Load (152.6ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  Category Load (151.3ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:83:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 4 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:87:in `serialize_prepare_result'
Completed 200 OK in 8467ms (Views: 0.3ms | ActiveRecord: 8128.5ms (47 queries, 8 cached) | GC: 12.8ms)


Started POST "/api/v1/marketplace/checkout/prepare" for ::1 at 2026-03-05 09:50:15 -0500
Processing by Api::V1::Marketplace::CheckoutController#prepare as */*
  Parameters: {"external_reference"=>"91a18b9f-cbaa-437f-8ebe-5ea09ee31549", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"8135518577", "document"=>""}, "order"=>{"amount"=>"1067920.0", "currency"=>"COP", "provider"=>"mock_provider"}, "checkout"=>{"external_reference"=>"91a18b9f-cbaa-437f-8ebe-5ea09ee31549", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"8135518577", "document"=>""}, "order"=>{"amount"=>"1067920.0", "currency"=>"COP", "provider"=>"mock_provider"}}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (153.5ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  TRANSACTION (157.4ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  PurchaseIntent Load (310.5ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."external_reference" = '91a18b9f-cbaa-437f-8ebe-5ea09ee31549' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  Purchase Load (151.2ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 4 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:27:in `block in call'
  Payment Load (150.8ms)  SELECT "payments".* FROM "payments" WHERE "payments"."purchase_id" = 4 AND "payments"."external_reference" = '91a18b9f-cbaa-437f-8ebe-5ea09ee31549' AND "payments"."provider" = 'mock_provider' ORDER BY "payments"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:42:in `block in call'
  Purchase Load (151.8ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 4 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:62:in `block in call'
  Payment Create (171.7ms)  INSERT INTO "payments" ("purchase_id", "external_reference", "provider", "provider_payment_id", "provider_preference_id", "status", "amount", "currency", "raw_payload", "created_at", "updated_at") VALUES (4, '91a18b9f-cbaa-437f-8ebe-5ea09ee31549', 'mock_provider', 'mock-1cade4b6-4bbf-49b0-be16-91af216e19a7', '28190482-f1f3-4c87-8050-6bba2f753765', 1, 1067920.0, 'COP', '{"payer":{"name":"JORGE CAMARGO","email":"jicsoftware1@gmail.com","phone":"8135518577","document":""},"order":{"amount":"1067920.0","currency":"COP","provider":"mock_provider"},"mock_auto_approved":true,"mock_auto_approved_at":"2026-03-05T14:50:17Z"}', '2026-03-05 14:50:17.535639', '2026-03-05 14:50:17.535639') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:62:in `block in call'
  TRANSACTION (153.9ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:23:in `call'
Completed 200 OK in 2188ms (Views: 0.2ms | ActiveRecord: 1706.5ms (6 queries, 0 cached) | GC: 1.3ms)


Started POST "/api/v1/marketplace/orders/complete" for ::1 at 2026-03-05 09:50:17 -0500
Processing by Api::V1::Marketplace::OrdersController#complete as */*
  Parameters: {"purchase_id"=>4, "order_ids"=>[4], "cart_id"=>3, "order"=>{"purchase_id"=>4}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (153.8ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  TRANSACTION (154.0ms)  BEGIN /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Purchase Load (312.0ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 4 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Order Exists? (151.1ms)  SELECT 1 AS one FROM "orders" WHERE "orders"."id" = 4 AND "orders"."purchase_id" = 4 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:31:in `block in call'
  Payment Exists? (156.2ms)  SELECT 1 AS one FROM "payments" WHERE "payments"."purchase_id" = 4 AND "payments"."status" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:59:in `ensure_approved_payment!'
  PurchaseIntent Load (151.1ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 4 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:34:in `block in call'
  PurchaseIntent Update (152.3ms)  UPDATE "purchase_intents" SET "status" = 1, "updated_at" = '2026-03-05 14:50:19.419788' WHERE "purchase_intents"."id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:35:in `block in call'
  Purchase Update (157.4ms)  UPDATE "purchases" SET "status" = 1, "updated_at" = '2026-03-05 14:50:19.573801' WHERE "purchases"."id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:38:in `block in call'
  Order Load (152.4ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 4 AND "orders"."purchase_id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:39:in `block in call'
  Order Update (153.2ms)  UPDATE "orders" SET "status" = 1, "updated_at" = '2026-03-05 14:50:19.885965' WHERE "orders"."id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:39:in `block (2 levels) in call'
  Cart Load (151.4ms)  SELECT "carts".* FROM "carts" WHERE "carts"."id" = 3 AND "carts"."user_id" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:89:in `complete_cart!'
  Cart Update (152.1ms)  UPDATE "carts" SET "status" = 1, "updated_at" = '2026-03-05 14:50:20.192894' WHERE "carts"."id" = 3 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:92:in `complete_cart!'
  TRANSACTION (152.4ms)  COMMIT /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:21:in `call'
  PurchaseItem Load (151.4ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (150.8ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Category Load (151.6ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (151.5ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 19 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Category Load (151.8ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 4 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (151.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 36 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Category Load (153.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (153.1ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 34 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Category Load (151.6ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (151.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 35 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  Product Load (150.6ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 29 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:44:in `complete'
  OrderItem Load (154.2ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 7 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 1 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 19 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 4 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 36 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.1ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 34 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 35 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 5 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" = 29 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" = 6 LIMIT 1
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:45:in `complete'
Completed 200 OK in 4433ms (Views: 0.1ms | ActiveRecord: 3970.9ms (37 queries, 14 cached) | GC: 4.7ms)


Started GET "/api/v1/marketplace/cart" for ::1 at 2026-03-05 09:50:19 -0500
Processing by Api::V1::Marketplace::CartsController#show as */*
  Parameters: {"cart"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (158.0ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
Updating Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b with role: admin
Successfully updated Supabase app_metadata for user 48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b
  Cart Load (157.3ms)  SELECT "carts".* FROM "carts" WHERE "carts"."user_id" = 1 AND "carts"."status" = 0 ORDER BY "carts"."created_at" DESC LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/marketplace/carts/fetch_open.rb:25:in `call'
Completed 200 OK in 894ms (Views: 0.2ms | ActiveRecord: 315.1ms (2 queries, 0 cached) | GC: 0.6ms)


## Analisis y recomendaciones (flujo actual)

### Resumen del estado actual
- El flujo funcional completo es correcto: `orders/prepare` -> `checkout/prepare` -> `orders/complete` -> `cart/show`, todo con `200 OK`.
- Ya se observa mejora funcional respecto a la version previa: se crean `order_items`, se actualiza perfil de usuario cuando aplica, y `complete` valida pago aprobado.
- El principal problema actual es rendimiento: tiempos altos en `prepare` (`~8.5s`) y `complete` (`~4.4s`), con muchas consultas por request.

### Hallazgos de rendimiento y posibles N+1
- **N+1 en reconstruccion de items:** durante `orders/prepare` se hace `Product Load` por cada item para crear `purchase_items` y luego otro `Product Load` por cada item para `order_items`.
- **N+1 en serializacion:** al responder `orders/prepare` y `orders/complete` se ven multiples `Category Load` y `Product Load` asociados a blueprints (carga repetitiva por item).
- **Consultas redundantes:** dentro del flujo hay cargas repetidas de `Purchase`/`PurchaseIntent` que pueden evitarse reutilizando objetos ya obtenidos en memoria.
- **Costo fijo por autenticacion:** en cada endpoint se hace fetch de JWKS y update de metadata en Supabase; eso agrega latencia transversal al flujo.

### Recomendaciones prioritarias
1. **Eliminar N+1 de productos en `prepare`:** precargar todos los productos del carrito en una sola consulta (`where(id: ids).index_by(&:id)`) y reutilizarlos para crear `purchase_items` y `order_items`.
2. **Eliminar N+1 de serializacion en controller:** cargar relaciones antes de renderizar:
   - `purchase` con `purchase_items: { product: :category }`
   - `orders` con `order_items: { product: :category }`
   Esto reduce `Product Load`/`Category Load` repetidos.
3. **Reducir lecturas duplicadas en interactors:** evitar `find`/`load` de entidades ya disponibles (`purchase`, `purchase_intent`, `order`) dentro de la misma transaccion.
4. **Optimizar autenticacion:** cachear JWKS (TTL) y evitar `update Supabase metadata` en cada request cuando no hay cambio real de rol.
5. **Mantener transaccion unica e idempotente:** conservar estrategia rebuild actual, pero considerar `insert_all`/operaciones por lote para items si el volumen crece.
6. **Monitoreo recomendado:** instrumentar por etapa (`auth`, `prepare_db`, `serialize`, `checkout_prepare`, `complete`) para medir impacto de cada optimizacion.

### Riesgo residual
- Aunque no hay errores funcionales en este log, con el volumen actual de queries el endpoint puede degradarse mas con carritos grandes o concurrencia alta.



----------------------------------

NUEVO FLUJO CON LAS RECOMENDACIONES ANTERIORES APLICADAS



Started POST "/api/v1/marketplace/orders/prepare" for ::1 at 2026-03-05 10:24:55 -0500
Processing by Api::V1::Marketplace::OrdersController#prepare as */*
  Parameters: {"cart_items"=>[{"product_id"=>13, "quantity"=>1, "price"=>"96910.0", "metadata"=>{}}, {"product_id"=>25, "quantity"=>1, "price"=>"136360.0", "metadata"=>{}}, {"product_id"=>26, "quantity"=>3, "price"=>"105970.0", "metadata"=>{}}], "shipping_address"=>{"street"=>"CR 5 SUR 83 200 CON RES LA FLORIDA 1", "city"=>"IBAGUE", "state"=>"Tolima", "zipCode"=>"730005", "phone"=>"285445665"}, "recipient_info"=>{"is_different"=>false, "name"=>"PEDRO CAMANEI", "phone"=>"285445665"}, "selected_date"=>"2026-03-06", "shipping_cost"=>"0", "payment_method"=>"credit_card", "purchase_intent_id"=>nil, "update_user_profile"=>true, "order"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (197.9ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  Product Pluck (200.0ms)  SELECT "products"."id" FROM "products" WHERE "products"."id" IN (13, 25, 26) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `validate_cart_products!'
  TRANSACTION (188.1ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:97:in `find_or_initialize_purchase_intent'
  PurchaseIntent Create (403.8ms)  INSERT INTO "purchase_intents" ("user_id", "company_id", "external_reference", "status", "total_amount", "created_at", "updated_at") VALUES (1, NULL, '1a1e07e6-be96-44b1-8ecb-a033be5dfedc', 0, 551180.0, '2026-03-05 15:24:59.171284', '2026-03-05 15:24:59.171284') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:97:in `find_or_initialize_purchase_intent'
  Purchase Load (198.9ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 5 AND "purchases"."user_id" = 1 ORDER BY "purchases"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:112:in `find_or_initialize_purchase'
  PurchaseIntent Load (191.9ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:124:in `find_or_initialize_purchase'
  Purchase Create (202.5ms)  INSERT INTO "purchases" ("purchase_intent_id", "user_id", "company_id", "total_amount", "subtotal_amount", "tax_amount", "shipping_cost", "status", "purchase_number", "shipping_address", "recipient_name", "recipient_phone", "created_at", "updated_at") VALUES (5, 1, NULL, 551180.0, 551180.0, 0.0, 0.0, 0, 'PUR-20260305152459-1', '{"street":"CR 5 SUR 83 200 CON RES LA FLORIDA 1","city":"IBAGUE","state":"Tolima","zipCode":"730005","phone":"285445665"}', 'PEDRO CAMANEI', '285445665', '2026-03-05 15:25:00.172300', '2026-03-05 15:25:00.172300') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:124:in `find_or_initialize_purchase'
  PurchaseItem Delete All (198.9ms)  DELETE FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 5 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:138:in `rebuild_purchase_items!'
  PurchaseItem Bulk Insert (190.5ms)  INSERT INTO "purchase_items" ("purchase_id","product_id","quantity","unit_price","line_subtotal","line_tax","line_total","metadata","created_at","updated_at") VALUES (5, 13, 1, 96910.0, 96910.0, 0.0, 96910.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976'), (5, 25, 1, 136360.0, 136360.0, 0.0, 136360.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976'), (5, 26, 3, 105970.0, 317910.0, 0.0, 317910.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:162:in `rebuild_purchase_items!'
  Order Load (188.7ms)  SELECT "orders".* FROM "orders" WHERE "orders"."purchase_id" = 5 ORDER BY "orders"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:168:in `find_or_initialize_order'
  Purchase Load (192.0ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:174:in `find_or_initialize_order'
  Order Create (191.6ms)  INSERT INTO "orders" ("purchase_id", "status", "total_amount", "shipping_date_estimated", "shipping_date_real", "tracking_info", "created_at", "updated_at") VALUES (5, 0, 551180.0, '2026-03-06 00:00:00', NULL, '{}', '2026-03-05 15:25:01.743471', '2026-03-05 15:25:01.743471') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:174:in `find_or_initialize_order'
  OrderItem Delete All (187.1ms)  DELETE FROM "order_items" WHERE "order_items"."order_id" = 5 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:179:in `rebuild_order_items!'
  OrderItem Bulk Insert (192.9ms)  INSERT INTO "order_items" ("order_id","product_id","quantity","price","metadata","created_at","updated_at") VALUES (5, 13, 1, 96910.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976'), (5, 25, 1, 136360.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976'), (5, 26, 3, 105970.0, '{}', '2026-03-05 15:25:00.577976', '2026-03-05 15:25:00.577976') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:193:in `rebuild_order_items!'
  User Update (185.8ms)  UPDATE "users" SET "updated_at" = '2026-03-05 15:25:02.963162', "phone" = '285445665', "address" = '{"street":"CR 5 SUR 83 200 CON RES LA FLORIDA 1","city":"IBAGUE","state":"Tolima","zipCode":"730005","phone":"285445665"}' WHERE "users"."id" = 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:225:in `update_user_profile_from_checkout!'
  TRANSACTION (187.1ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:53:in `call'
  Purchase Load (185.8ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  PurchaseItem Load (184.1ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 5 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Product Load (184.8ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (13, 25, 26) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Category Load (191.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (2, 4, 3) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Order Load (184.3ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  OrderItem Load (184.3ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 5 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (13, 25, 26)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (2, 4, 3)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
Completed 200 OK in 6299ms (Views: 0.2ms | ActiveRecord: 7336.5ms (22 queries, 2 cached) | GC: 5.3ms)


Started POST "/api/v1/marketplace/checkout/prepare" for ::1 at 2026-03-05 10:25:04 -0500
Processing by Api::V1::Marketplace::CheckoutController#prepare as */*
  Parameters: {"external_reference"=>"1a1e07e6-be96-44b1-8ecb-a033be5dfedc", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"285445665", "document"=>""}, "order"=>{"amount"=>"551180.0", "currency"=>"COP", "provider"=>"mock_provider"}, "checkout"=>{"external_reference"=>"1a1e07e6-be96-44b1-8ecb-a033be5dfedc", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"285445665", "document"=>""}, "order"=>{"amount"=>"551180.0", "currency"=>"COP", "provider"=>"mock_provider"}}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (191.1ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  TRANSACTION (185.9ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  PurchaseIntent Load (370.7ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."external_reference" = '1a1e07e6-be96-44b1-8ecb-a033be5dfedc' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:25:in `block in call'
  Purchase Load (184.9ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:27:in `block in call'
  Payment Load (191.3ms)  SELECT "payments".* FROM "payments" WHERE "payments"."purchase_id" = 5 AND "payments"."external_reference" = '1a1e07e6-be96-44b1-8ecb-a033be5dfedc' AND "payments"."provider" = 'mock_provider' ORDER BY "payments"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:42:in `block in call'
  Purchase Load (184.2ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 5 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:62:in `block in call'
  Payment Create (201.8ms)  INSERT INTO "payments" ("purchase_id", "external_reference", "provider", "provider_payment_id", "provider_preference_id", "status", "amount", "currency", "raw_payload", "created_at", "updated_at") VALUES (5, '1a1e07e6-be96-44b1-8ecb-a033be5dfedc', 'mock_provider', 'mock-c3c4b86c-8efc-4b9b-a869-366c282d9a83', '007d7069-b1c0-40ca-bce9-11c8c78fe39e', 1, 551180.0, 'COP', '{"payer":{"name":"JORGE CAMARGO","email":"jicsoftware1@gmail.com","phone":"285445665","document":""},"order":{"amount":"551180.0","currency":"COP","provider":"mock_provider"},"mock_auto_approved":true,"mock_auto_approved_at":"2026-03-05T15:25:05Z"}', '2026-03-05 15:25:05.860424', '2026-03-05 15:25:05.860424') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:62:in `block in call'
  TRANSACTION (186.9ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:23:in `call'
Completed 200 OK in 1714ms (Views: 0.1ms | ActiveRecord: 1696.6ms (6 queries, 0 cached) | GC: 0.0ms)


Started POST "/api/v1/marketplace/orders/complete" for ::1 at 2026-03-05 10:25:06 -0500
Processing by Api::V1::Marketplace::OrdersController#complete as */*
  Parameters: {"purchase_id"=>5, "order_ids"=>[5], "cart_id"=>4, "order"=>{"purchase_id"=>5}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (191.6ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  TRANSACTION (183.1ms)  BEGIN /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Purchase Load (370.0ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 5 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:22:in `block in call'
  Order Exists? (186.4ms)  SELECT 1 AS one FROM "orders" WHERE "orders"."id" = 5 AND "orders"."purchase_id" = 5 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:31:in `block in call'
  Payment Exists? (190.0ms)  SELECT 1 AS one FROM "payments" WHERE "payments"."purchase_id" = 5 AND "payments"."status" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:59:in `ensure_approved_payment!'
  PurchaseIntent Load (183.1ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 5 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:34:in `block in call'
  PurchaseIntent Update (195.1ms)  UPDATE "purchase_intents" SET "status" = 1, "updated_at" = '2026-03-05 15:25:07.654809' WHERE "purchase_intents"."id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:35:in `block in call'
  Purchase Update (186.2ms)  UPDATE "purchases" SET "status" = 1, "updated_at" = '2026-03-05 15:25:07.851808' WHERE "purchases"."id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:38:in `block in call'
  Order Load (186.5ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 5 AND "orders"."purchase_id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:39:in `block in call'
  Order Update (190.2ms)  UPDATE "orders" SET "status" = 1, "updated_at" = '2026-03-05 15:25:08.226993' WHERE "orders"."id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:39:in `block (2 levels) in call'
  Cart Load (191.0ms)  SELECT "carts".* FROM "carts" WHERE "carts"."id" = 4 AND "carts"."user_id" = 1 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:89:in `complete_cart!'
  Cart Update (186.4ms)  UPDATE "carts" SET "status" = 1, "updated_at" = '2026-03-05 15:25:08.614683' WHERE "carts"."id" = 4 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:92:in `complete_cart!'
  TRANSACTION (186.1ms)  COMMIT /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/complete.rb:21:in `call'
  Purchase Load (189.1ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 5 LIMIT 1 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:46:in `complete'
  PurchaseItem Load (190.7ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:46:in `complete'
  Product Load (190.7ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (13, 25, 26) /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:46:in `complete'
  Category Load (185.9ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (2, 4, 3) /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:46:in `complete'
  Order Load (186.7ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:54:in `complete'
  OrderItem Load (185.9ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 5 /*action='complete',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:54:in `complete'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (13, 25, 26)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:54:in `complete'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (2, 4, 3)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:54:in `complete'
Completed 200 OK in 3815ms (Views: 0.1ms | ActiveRecord: 3754.0ms (19 queries, 2 cached) | GC: 1.4ms)


Started GET "/api/v1/marketplace/cart" for ::1 at 2026-03-05 10:25:10 -0500
Processing by Api::V1::Marketplace::CartsController#show as */*
  Parameters: {"cart"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (190.6ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  Cart Load (190.9ms)  SELECT "carts".* FROM "carts" WHERE "carts"."user_id" = 1 AND "carts"."status" = 0 ORDER BY "carts"."created_at" DESC LIMIT 1 /*action='show',application='QvitalBackend',controller='carts'*/
  ↳ app/interactors/marketplace/carts/fetch_open.rb:25:in `call'
Completed 200 OK in 659ms (Views: 0.2ms | ActiveRecord: 381.4ms (2 queries, 0 cached) | GC: 0.1ms)
