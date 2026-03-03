class AddPositionToCategories < ActiveRecord::Migration[8.0]
  def change
    add_column :categories, :position, :integer, default: 0, null: false
    add_index :categories, :position
  end
end
