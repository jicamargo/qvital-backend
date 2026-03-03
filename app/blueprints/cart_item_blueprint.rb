class CartItemBlueprint < Blueprinter::Base
  identifier :id

  fields :quantity, :price_snapshot, :metadata

  association :product, blueprint: ProductBlueprint
end

