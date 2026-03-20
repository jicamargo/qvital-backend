# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_05_130000) do
  create_schema "auth"
  create_schema "extensions"
  create_schema "graphql"
  create_schema "graphql_public"
  create_schema "pgbouncer"
  create_schema "realtime"
  create_schema "storage"
  create_schema "vault"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price_snapshot", precision: 10, scale: 2, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_id"], name: "index_cart_items_on_cart_id_and_product_id"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_carts_on_user_id_and_status"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position", default: 0, null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["position"], name: "index_categories_on_position"
  end

  create_table "health_checks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "levels", force: :cascade do |t|
    t.string "name", null: false
    t.integer "priority", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_levels_on_name", unique: true
    t.index ["priority"], name: "index_levels_on_priority"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.datetime "shipping_date_estimated"
    t.datetime "shipping_date_real"
    t.jsonb "tracking_info", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["purchase_id"], name: "index_orders_on_purchase_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.string "external_reference", null: false
    t.string "provider", null: false
    t.string "provider_payment_id"
    t.string "provider_preference_id"
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", default: "'COP'::character varying", null: false
    t.jsonb "raw_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_reference"], name: "index_payments_on_external_reference"
    t.index ["provider"], name: "index_payments_on_provider"
    t.index ["purchase_id"], name: "index_payments_on_purchase_id"
  end

  create_table "product_prices", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "level_id", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["level_id"], name: "index_product_prices_on_level_id"
    t.index ["product_id", "level_id"], name: "index_product_prices_on_product_id_and_level_id", unique: true
    t.index ["product_id"], name: "index_product_prices_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "image_url"
    t.boolean "active", default: true, null: false
    t.decimal "pv", precision: 10, scale: 2
    t.string "sku"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image_path"
    t.index ["active"], name: "index_products_on_active"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "purchase_intents", force: :cascade do |t|
    t.bigint "user_id"
    t.integer "company_id"
    t.string "external_reference", null: false
    t.integer "status", default: 0, null: false
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_purchase_intents_on_company_id"
    t.index ["external_reference"], name: "index_purchase_intents_on_external_reference", unique: true
    t.index ["user_id"], name: "index_purchase_intents_on_user_id"
  end

  create_table "purchase_items", force: :cascade do |t|
    t.bigint "purchase_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "line_subtotal", precision: 12, scale: 2, null: false
    t.decimal "line_tax", precision: 12, scale: 2, null: false
    t.decimal "line_total", precision: 12, scale: 2, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_purchase_items_on_product_id"
    t.index ["purchase_id"], name: "index_purchase_items_on_purchase_id"
  end

  create_table "purchases", force: :cascade do |t|
    t.bigint "purchase_intent_id", null: false
    t.bigint "user_id"
    t.integer "company_id"
    t.decimal "total_amount", precision: 12, scale: 2, null: false
    t.decimal "subtotal_amount", precision: 12, scale: 2, null: false
    t.decimal "tax_amount", precision: 12, scale: 2, null: false
    t.decimal "shipping_cost", precision: 12, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.string "purchase_number", null: false
    t.jsonb "shipping_address", default: {}, null: false
    t.string "recipient_name"
    t.string "recipient_phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_purchases_on_company_id"
    t.index ["purchase_intent_id"], name: "index_purchases_on_purchase_intent_id"
    t.index ["purchase_number"], name: "index_purchases_on_purchase_number", unique: true
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password"
    t.string "role", default: "cliente", null: false
    t.bigint "level_id"
    t.string "supabase_uid"
    t.string "hlf_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone"
    t.jsonb "address", default: {}, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["hlf_id"], name: "index_users_on_hlf_id", unique: true
    t.index ["level_id"], name: "index_users_on_level_id"
    t.index ["role"], name: "index_users_on_role"
    t.index ["supabase_uid"], name: "index_users_on_supabase_uid", unique: true
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "purchases"
  add_foreign_key "payments", "purchases"
  add_foreign_key "product_prices", "levels"
  add_foreign_key "product_prices", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "purchase_intents", "users"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "purchase_intents"
  add_foreign_key "purchases", "users"
  add_foreign_key "users", "levels"
end
