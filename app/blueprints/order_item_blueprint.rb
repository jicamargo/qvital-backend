class OrderItemBlueprint < Blueprinter::Base
  identifier :id

  fields :quantity, :price, :metadata

  association :product, blueprint: ProductBlueprint
end

