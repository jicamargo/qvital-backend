class AddImagePathToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :image_path, :string
  end
end
