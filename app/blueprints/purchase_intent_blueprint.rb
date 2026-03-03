class PurchaseIntentBlueprint < Blueprinter::Base
  identifier :id

  fields :external_reference, :status, :total_amount, :created_at, :updated_at
end

