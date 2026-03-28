Started POST "/api/v1/marketplace/orders/prepare" for ::1 at 2026-03-23 18:10:43 -0500
Processing by Api::V1::Marketplace::OrdersController#prepare as */*
  Parameters: {"cart_items"=>[{"product_id"=>7, "quantity"=>1, "price"=>"104490.0", "metadata"=>{}}, {"product_id"=>26, "quantity"=>1, "price"=>"105970.0", "metadata"=>{}}], "shipping_address"=>{"street"=>"DIR EN LAAPP QVITAL", "city"=>"ARMENIA", "state"=>"QUINDIO", "zipCode"=>"6565656", "phone"=>"33311113333"}, "recipient_info"=>{"is_different"=>false, "name"=>"nombreen qvitalapp", "phone"=>"33311113333"}, "selected_date"=>"2026-03-24", "shipping_cost"=>"0", "payment_method"=>"credit_card", "purchase_intent_id"=>nil, "update_user_profile"=>false, "order"=>{}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (308.6ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  Product Pluck (322.7ms)  SELECT "products"."id" FROM "products" WHERE "products"."id" IN (7, 26) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:130:in `validate_cart_products!'
  TRANSACTION (318.1ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:97:in `find_or_initialize_purchase_intent'
  PurchaseIntent Create (623.5ms)  INSERT INTO "purchase_intents" ("user_id", "company_id", "external_reference", "status", "total_amount", "created_at", "updated_at") VALUES (1, NULL, '24605567-9199-4aae-bff0-75064af4c06c', 0, 210460.0, '2026-03-23 23:10:44.861768', '2026-03-23 23:10:44.861768') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:97:in `find_or_initialize_purchase_intent'
  Purchase Load (303.2ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 19 AND "purchases"."user_id" = 1 ORDER BY "purchases"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:112:in `find_or_initialize_purchase'
  PurchaseIntent Load (317.5ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:124:in `find_or_initialize_purchase'
  Purchase Create (850.6ms)  INSERT INTO "purchases" ("purchase_intent_id", "user_id", "company_id", "total_amount", "subtotal_amount", "tax_amount", "shipping_cost", "status", "purchase_number", "shipping_address", "recipient_name", "recipient_phone", "created_at", "updated_at") VALUES (19, 1, NULL, 210460.0, 210460.0, 0.0, 0.0, 0, 'PUR-20260323231045-1', '{"street":"DIR EN LAAPP QVITAL","city":"ARMENIA","state":"QUINDIO","zipCode":"6565656","phone":"33311113333"}', 'nombreen qvitalapp', '33311113333', '2026-03-23 23:10:45.988143', '2026-03-23 23:10:45.988143') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:124:in `find_or_initialize_purchase'
  PurchaseItem Delete All (315.0ms)  DELETE FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 19 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:138:in `rebuild_purchase_items!'
  PurchaseItem Bulk Insert (848.7ms)  INSERT INTO "purchase_items" ("purchase_id","product_id","quantity","unit_price","line_subtotal","line_tax","line_total","metadata","created_at","updated_at") VALUES (19, 7, 1, 104490.0, 104490.0, 0.0, 104490.0, '{}', '2026-03-23 23:10:47.160040', '2026-03-23 23:10:47.160040'), (19, 26, 1, 105970.0, 105970.0, 0.0, 105970.0, '{}', '2026-03-23 23:10:47.160040', '2026-03-23 23:10:47.160040') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:162:in `rebuild_purchase_items!'
  Order Load (310.4ms)  SELECT "orders".* FROM "orders" WHERE "orders"."purchase_id" = 19 ORDER BY "orders"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:168:in `find_or_initialize_order'
  Purchase Load (295.8ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:174:in `find_or_initialize_order'
  Order Create (312.3ms)  INSERT INTO "orders" ("purchase_id", "status", "total_amount", "shipping_date_estimated", "shipping_date_real", "tracking_info", "created_at", "updated_at") VALUES (19, 0, 210460.0, '2026-03-24 00:00:00', NULL, '{}', '2026-03-23 23:10:48.624919', '2026-03-23 23:10:48.624919') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:174:in `find_or_initialize_order'
  OrderItem Delete All (313.0ms)  DELETE FROM "order_items" WHERE "order_items"."order_id" = 19 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:179:in `rebuild_order_items!'
  OrderItem Bulk Insert (332.8ms)  INSERT INTO "order_items" ("order_id","product_id","quantity","price","metadata","created_at","updated_at") VALUES (19, 7, 1, 104490.0, '{}', '2026-03-23 23:10:47.160040', '2026-03-23 23:10:47.160040'), (19, 26, 1, 105970.0, '{}', '2026-03-23 23:10:47.160040', '2026-03-23 23:10:47.160040') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:193:in `rebuild_order_items!'
  TRANSACTION (339.5ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/interactors/marketplace/orders/prepare.rb:53:in `call'
  Purchase Load (862.2ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  PurchaseItem Load (314.5ms)  SELECT "purchase_items".* FROM "purchase_items" WHERE "purchase_items"."purchase_id" = 19 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Product Load (314.4ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (7, 26) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Category Load (309.8ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 3) /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:88:in `serialize_prepare_result'
  Order Load (305.2ms)  SELECT "orders".* FROM "orders" WHERE "orders"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  OrderItem Load (311.9ms)  SELECT "order_items".* FROM "order_items" WHERE "order_items"."order_id" = 19 /*action='prepare',application='QvitalBackend',controller='orders'*/
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  CACHE Product Load (0.0ms)  SELECT "products".* FROM "products" WHERE "products"."id" IN (7, 26)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
  CACHE Category Load (0.0ms)  SELECT "categories".* FROM "categories" WHERE "categories"."id" IN (1, 3)
  ↳ app/controllers/api/v1/marketplace/orders_controller.rb:92:in `serialize_prepare_result'
Completed 200 OK in 9246ms (Views: 0.1ms | ActiveRecord: 8841.3ms (21 queries, 2 cached) | GC: 0.9ms)


Started POST "/api/v1/marketplace/checkout/prepare" for ::1 at 2026-03-23 18:10:51 -0500
Processing by Api::V1::Marketplace::CheckoutController#prepare as */*
  Parameters: {"external_reference"=>"24605567-9199-4aae-bff0-75064af4c06c", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"33311113333", "document"=>""}, "order"=>{"amount"=>"210460.0", "currency"=>"COP", "provider"=>"mock_provider"}, "checkout"=>{"external_reference"=>"24605567-9199-4aae-bff0-75064af4c06c", "payer"=>{"name"=>"JORGE CAMARGO", "email"=>"[FILTERED]", "phone"=>"33311113333", "document"=>""}, "order"=>{"amount"=>"210460.0", "currency"=>"COP", "provider"=>"mock_provider"}}}
Fetching JWKS from: https://olpphsgcoxdljdbdnnph.supabase.co/auth/v1/.well-known/jwks.json
  User Load (306.2ms)  SELECT "users".* FROM "users" WHERE "users"."supabase_uid" = '48bae3fc-deef-4c6d-8d6a-f94fe24e1d9b' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/auth/sync_user.rb:114:in `sync_user'
  TRANSACTION (319.1ms)  BEGIN /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:35:in `block in call'
  PurchaseIntent Load (643.3ms)  SELECT "purchase_intents".* FROM "purchase_intents" WHERE "purchase_intents"."external_reference" = '24605567-9199-4aae-bff0-75064af4c06c' LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:35:in `block in call'
  Purchase Load (325.5ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."purchase_intent_id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:37:in `block in call'
  Payment Load (848.7ms)  SELECT "payments".* FROM "payments" WHERE "payments"."purchase_id" = 19 AND "payments"."external_reference" = '24605567-9199-4aae-bff0-75064af4c06c' AND "payments"."provider" = 'mock_provider' ORDER BY "payments"."id" ASC LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:56:in `block in call'
  Purchase Load (849.5ms)  SELECT "purchases".* FROM "purchases" WHERE "purchases"."id" = 19 LIMIT 1 /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:71:in `block in call'
  Payment Create (855.1ms)  INSERT INTO "payments" ("purchase_id", "external_reference", "provider", "provider_payment_id", "provider_preference_id", "status", "amount", "currency", "raw_payload", "created_at", "updated_at") VALUES (19, '24605567-9199-4aae-bff0-75064af4c06c', 'mock_provider', NULL, '24605567-9199-4aae-bff0-75064af4c06c', 0, 210460.0, 'COP', '{"payer":{"name":"JORGE CAMARGO","email":"jicsoftware1@gmail.com","phone":"33311113333","document":""},"order":{"amount":"210460.0","currency":"COP","provider":"mock_provider"},"wompi_checkout":{"checkout_url":"https://checkout.wompi.co/p/","fields":{"public-key":"pub_test_DDZEwkIhkqzau6VXaw8oJZHOisumrvAz","currency":"COP","amount-in-cents":"21046000","reference":"24605567-9199-4aae-bff0-75064af4c06c","signature:integrity":"43aaffaf1b5bae05d69545db832d704d7fac047eddae01b75367abda7edf6bf7","redirect-url":"https://api-staging.pitz.com.mx/marketplace/checkout/result","customer-data:email":"jicsoftware1@gmail.com","customer-data:full-name":"JORGE CAMARGO","customer-data:phone-number":"33311113333","customer-data:phone-number-prefix":"+57"}}}', '2026-03-23 23:11:00.662600', '2026-03-23 23:11:00.662600') RETURNING "id" /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:71:in `block in call'
  TRANSACTION (326.1ms)  COMMIT /*action='prepare',application='QvitalBackend',controller='checkout'*/
  ↳ app/interactors/marketplace/checkout/prepare.rb:33:in `call'
Completed 200 OK in 4539ms (Views: 0.3ms | ActiveRecord: 4473.1ms (6 queries, 0 cached) | GC: 2.2ms)


