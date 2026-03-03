class AddImagePathToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :image_path, :string
  end
end

