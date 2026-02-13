class CreateProductPrices < ActiveRecord::Migration[8.0]
  def change
    create_table :product_prices do |t|
      t.references :product, null: false, foreign_key: true
      t.references :level, null: false, foreign_key: true
      t.decimal :price, null: false, precision: 10, scale: 2

      t.timestamps
    end

    add_index :product_prices, [:product_id, :level_id], unique: true
  end
end
