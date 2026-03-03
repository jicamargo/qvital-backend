class OrderBlueprint < Blueprinter::Base
  identifier :id

  fields :status,
         :total_amount,
         :shipping_date_estimated,
         :shipping_date_real,
         :tracking_info,
         :created_at,
         :updated_at

  association :order_items, blueprint: OrderItemBlueprint
end

