class ProductBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :description, :long_description, :image_url, :pv, :sku, :flavor, :disclaimer, :premium_days

  field :price do |product, options|
    level_id = options[:level_id]
    # Solo calcular precio si se pasa level_id (marketplace público)
    # En admin no se pasa level_id, así que retornamos null
    product.price_for_level(level_id) if level_id
  end

  field :level_id do |_product, options|
    options[:level_id]
  end

  field :currency do
    'COP'
  end

  association :category, blueprint: CategoryBlueprint
  association :health_goals, blueprint: HealthGoalBlueprint

  view :admin do
    include_view :default
    fields :active, :created_at, :updated_at

    # Precio por nivel para el formulario del admin: { "<level_id>" => precio }.
    field :prices do |product|
      product.product_prices.to_h { |pp| [ pp.level_id.to_s, pp.price ] }
    end
  end
end
