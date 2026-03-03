class PurchaseBlueprint < Blueprinter::Base
  identifier :id

  fields :total_amount,
         :subtotal_amount,
         :tax_amount,
         :shipping_cost,
         :status,
         :purchase_number,
         :shipping_address,
         :recipient_name,
         :recipient_phone,
         :created_at,
         :updated_at

  association :purchase_items, blueprint: PurchaseItemBlueprint
end

