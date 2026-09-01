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

ActiveRecord::Schema[8.0].define(version: 2026_09_01_120000) do
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
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "body_emotion_insights", force: :cascade do |t|
    t.bigint "body_region_id", null: false
    t.text "symptom_pattern", null: false
    t.string "emotional_theme", null: false
    t.text "narrative_explanation", null: false
    t.jsonb "reflective_questions", default: [], null: false
    t.text "integration_guidance", null: false
    t.integer "severity_flag", default: 0, null: false
    t.jsonb "tags", default: [], null: false
    t.integer "status", default: 0, null: false
    t.text "content_curation_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_region_id", "status"], name: "index_body_emotion_insights_on_body_region_id_and_status"
    t.index ["body_region_id"], name: "index_body_emotion_insights_on_body_region_id"
  end

  create_table "body_regions", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "body_system", null: false
    t.integer "display_order", default: 0, null: false
    t.string "illustration_ref"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_system", "display_order"], name: "index_body_regions_on_body_system_and_display_order"
    t.index ["name"], name: "index_body_regions_on_name", unique: true
    t.index ["parent_id"], name: "index_body_regions_on_parent_id"
  end

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

  create_table "coach_consultation_entries", force: :cascade do |t|
    t.bigint "coach_consultation_id", null: false
    t.integer "sequence", null: false
    t.integer "entry_type", null: false
    t.bigint "body_region_id"
    t.bigint "body_emotion_insight_id"
    t.text "user_input"
    t.jsonb "system_response_payload", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["body_emotion_insight_id"], name: "index_coach_consultation_entries_on_body_emotion_insight_id"
    t.index ["body_region_id"], name: "index_coach_consultation_entries_on_body_region_id"
    t.index ["coach_consultation_id", "sequence"], name: "idx_on_coach_consultation_id_sequence_72b23cb2fc", unique: true
    t.index ["coach_consultation_id"], name: "index_coach_consultation_entries_on_coach_consultation_id"
  end

  create_table "coach_consultations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "virtual_coach_profile_id", null: false
    t.datetime "started_at", null: false
    t.datetime "ended_at"
    t.integer "status", default: 0, null: false
    t.text "session_summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "status"], name: "index_coach_consultations_on_user_id_and_status"
    t.index ["user_id"], name: "index_coach_consultations_on_user_id"
    t.index ["virtual_coach_profile_id"], name: "index_coach_consultations_on_virtual_coach_profile_id"
  end

  create_table "health_checks", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "health_goals", force: :cascade do |t|
    t.string "key", null: false
    t.string "name", null: false
    t.text "description"
    t.string "icon", null: false
    t.string "color", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_health_goals_on_key", unique: true
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

  create_table "product_health_goals", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "health_goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["health_goal_id"], name: "index_product_health_goals_on_health_goal_id"
    t.index ["product_id", "health_goal_id"], name: "index_product_health_goals_on_product_and_goal", unique: true
    t.index ["product_id"], name: "index_product_health_goals_on_product_id"
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
    t.string "flavor"
    t.text "disclaimer"
    t.text "long_description"
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
    t.datetime "medical_disclaimer_accepted_at"
    t.index ["company_id"], name: "index_purchases_on_company_id"
    t.index ["purchase_intent_id"], name: "index_purchases_on_purchase_intent_id"
    t.index ["purchase_number"], name: "index_purchases_on_purchase_number", unique: true
    t.index ["user_id"], name: "index_purchases_on_user_id"
  end

  create_table "recipe_health_goals", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "health_goal_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["health_goal_id"], name: "index_recipe_health_goals_on_health_goal_id"
    t.index ["recipe_id", "health_goal_id"], name: "index_recipe_health_goals_on_recipe_and_goal", unique: true
    t.index ["recipe_id"], name: "index_recipe_health_goals_on_recipe_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "product_id"
    t.string "generic_name"
    t.string "quantity", null: false
    t.boolean "is_optional", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_recipe_ingredients_on_product_id"
    t.index ["recipe_id", "position"], name: "index_recipe_ingredients_on_recipe_id_and_position"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "title", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "servings", default: 1, null: false
    t.integer "prep_time_minutes"
    t.integer "difficulty", default: 0, null: false
    t.jsonb "instructions", default: [], null: false
    t.string "image_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "calories"
    t.decimal "protein_g", precision: 6, scale: 2
    t.decimal "carbs_g", precision: 6, scale: 2
    t.decimal "fat_g", precision: 6, scale: 2
    t.decimal "fiber_g", precision: 6, scale: 2
    t.integer "recipe_type"
    t.text "tips"
    t.string "source"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
  end

  create_table "user_feature_usages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "feature_key", null: false
    t.datetime "last_used_at", null: false
    t.integer "use_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "feature_key"], name: "index_user_feature_usages_on_user_id_and_feature_key", unique: true
    t.index ["user_id"], name: "index_user_feature_usages_on_user_id"
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
    t.string "last_name"
    t.boolean "premium_active", default: false, null: false
    t.datetime "premium_expires_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["hlf_id"], name: "index_users_on_hlf_id", unique: true
    t.index ["level_id"], name: "index_users_on_level_id"
    t.index ["role"], name: "index_users_on_role"
    t.index ["supabase_uid"], name: "index_users_on_supabase_uid", unique: true
  end

  create_table "virtual_coach_profiles", force: :cascade do |t|
    t.string "display_name", null: false
    t.integer "gender", default: 0, null: false
    t.string "specialty_description", default: "Conexión Cuerpo-Emoción", null: false
    t.jsonb "tone_profile", default: {}, null: false
    t.string "avatar_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_virtual_coach_profiles_on_active"
  end

  add_foreign_key "body_emotion_insights", "body_regions"
  add_foreign_key "body_regions", "body_regions", column: "parent_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "coach_consultation_entries", "body_emotion_insights"
  add_foreign_key "coach_consultation_entries", "body_regions"
  add_foreign_key "coach_consultation_entries", "coach_consultations"
  add_foreign_key "coach_consultations", "users"
  add_foreign_key "coach_consultations", "virtual_coach_profiles"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "purchases"
  add_foreign_key "payments", "purchases"
  add_foreign_key "product_health_goals", "health_goals"
  add_foreign_key "product_health_goals", "products"
  add_foreign_key "product_prices", "levels"
  add_foreign_key "product_prices", "products"
  add_foreign_key "products", "categories"
  add_foreign_key "purchase_intents", "users"
  add_foreign_key "purchase_items", "products"
  add_foreign_key "purchase_items", "purchases"
  add_foreign_key "purchases", "purchase_intents"
  add_foreign_key "purchases", "users"
  add_foreign_key "recipe_health_goals", "health_goals"
  add_foreign_key "recipe_health_goals", "recipes"
  add_foreign_key "recipe_ingredients", "products"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "user_feature_usages", "users"
  add_foreign_key "users", "levels"
end
