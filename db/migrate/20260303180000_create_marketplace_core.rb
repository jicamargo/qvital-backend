class CreateMarketplaceCore < ActiveRecord::Migration[8.0]
  def change
    create_table :carts do |t|
      t.references :user, null: true, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :carts, [:user_id, :status]

    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :price_snapshot, null: false, precision: 10, scale: 2
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :cart_items, [:cart_id, :product_id]

    create_table :purchase_intents do |t|
      t.references :user, null: true, foreign_key: true
      t.integer :company_id, null: true
      t.string :external_reference, null: false
      t.integer :status, null: false, default: 0
      t.decimal :total_amount, null: false, precision: 12, scale: 2

      t.timestamps
    end

    add_index :purchase_intents, :external_reference, unique: true
    add_index :purchase_intents, :company_id

    create_table :purchases do |t|
      t.references :purchase_intent, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.integer :company_id, null: true
      t.decimal :total_amount, null: false, precision: 12, scale: 2
      t.decimal :subtotal_amount, null: false, precision: 12, scale: 2
      t.decimal :tax_amount, null: false, precision: 12, scale: 2
      t.decimal :shipping_cost, null: false, precision: 12, scale: 2
      t.integer :status, null: false, default: 0
      t.string :purchase_number, null: false
      t.jsonb :shipping_address, null: false, default: {}
      t.string :recipient_name
      t.string :recipient_phone

      t.timestamps
    end

    add_index :purchases, :company_id
    add_index :purchases, :purchase_number, unique: true

    create_table :purchase_items do |t|
      t.references :purchase, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :unit_price, null: false, precision: 10, scale: 2
      t.decimal :line_subtotal, null: false, precision: 12, scale: 2
      t.decimal :line_tax, null: false, precision: 12, scale: 2
      t.decimal :line_total, null: false, precision: 12, scale: 2
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :orders do |t|
      t.references :purchase, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.decimal :total_amount, null: false, precision: 12, scale: 2
      t.datetime :shipping_date_estimated
      t.datetime :shipping_date_real
      t.jsonb :tracking_info, null: false, default: {}

      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :price, null: false, precision: 10, scale: 2
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    create_table :payments do |t|
      t.references :purchase, null: false, foreign_key: true
      t.string :external_reference, null: false
      t.string :provider, null: false
      t.string :provider_payment_id
      t.string :provider_preference_id
      t.integer :status, null: false, default: 0
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.string :currency, null: false, default: 'COP'
      t.jsonb :raw_payload, null: false, default: {}

      t.timestamps
    end

    add_index :payments, :external_reference
    add_index :payments, :provider
  end
end

