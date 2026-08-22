class AddMedicalDisclaimerAcceptedAtToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :medical_disclaimer_accepted_at, :datetime
  end
end
