class AddNutritionFieldsToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :calories, :integer
    add_column :recipes, :protein_g, :decimal, precision: 6, scale: 2
    add_column :recipes, :carbs_g, :decimal, precision: 6, scale: 2
    add_column :recipes, :fat_g, :decimal, precision: 6, scale: 2
    add_column :recipes, :fiber_g, :decimal, precision: 6, scale: 2
    add_column :recipes, :recipe_type, :integer
    add_column :recipes, :tips, :text
    add_column :recipes, :source, :string
  end
end
