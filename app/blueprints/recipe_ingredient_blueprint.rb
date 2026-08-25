class RecipeIngredientBlueprint < Blueprinter::Base
  identifier :id

  fields :quantity, :is_optional, :position, :generic_name, :product_id

  field :name do |ingredient|
    ingredient.product&.name || ingredient.generic_name
  end
end
