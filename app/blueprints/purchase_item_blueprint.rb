class PurchaseItemBlueprint < Blueprinter::Base
  identifier :id

  fields :quantity, :unit_price, :line_subtotal, :line_tax, :line_total, :metadata

  association :product, blueprint: ProductBlueprint
end

