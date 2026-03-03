class CartBlueprint < Blueprinter::Base
  identifier :id

  fields :status, :created_at, :updated_at

  association :cart_items, blueprint: CartItemBlueprint
end

