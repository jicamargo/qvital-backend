class AddLongDescriptionToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :long_description, :text
  end
end
