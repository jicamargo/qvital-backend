class AddPremiumStageTwoColumns < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :premium_days, :integer
    add_column :users, :premium_reminder_sent_for, :datetime
    add_column :orders, :shipped_notified_at, :datetime
  end
end
