class AddFlavorAndDisclaimerToProducts < ActiveRecord::Migration[8.0]
  def change
    change_table :products, bulk: true do |t|
      t.string :flavor
      t.text :disclaimer
    end
  end
end
