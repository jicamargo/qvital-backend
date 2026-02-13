class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.string :image_url
      t.boolean :active, null: false, default: true
      t.decimal :pv, precision: 10, scale: 2
      t.string :sku
      t.references :category, null: true, foreign_key: true

      t.timestamps
    end

    add_index :products, :active
    add_index :products, :sku, unique: true
  end
end
