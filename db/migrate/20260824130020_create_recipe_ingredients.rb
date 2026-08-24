class CreateRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_ingredients do |t|
      t.references :recipe, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.string  :generic_name
      t.string  :quantity, null: false
      t.boolean :is_optional, default: false, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :recipe_ingredients, [:recipe_id, :position]
  end
end
