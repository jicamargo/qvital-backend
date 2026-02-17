class ProductBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :image_url, :pv, :sku

  field :price do |product, options|
    level_id = options[:level_id]
    product.price_for_level(level_id)
  end

  field :level_id do |_product, options|
    options[:level_id]
  end

  field :currency do
    'MXN'
  end

  association :category, blueprint: CategoryBlueprint

  view :admin do
    include_view :default
    fields :active, :created_at, :updated_at
  end
end

