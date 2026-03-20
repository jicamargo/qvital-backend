class AddPhoneAndAddressToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :address, :jsonb, default: {}, null: false
  end
end
