class CreateBodyRegions < ActiveRecord::Migration[8.0]
  def change
    create_table :body_regions do |t|
      t.string :name, null: false
      t.references :parent, null: true, foreign_key: { to_table: :body_regions }
      t.integer :body_system, null: false
      t.integer :display_order, null: false, default: 0
      t.string :illustration_ref
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :body_regions, :name, unique: true
    add_index :body_regions, [:body_system, :display_order]
  end
end
