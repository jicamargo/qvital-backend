class RecipeBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :slug, :description, :servings, :prep_time_minutes, :difficulty, :image_url

  association :health_goals, blueprint: HealthGoalBlueprint

  view :detail do
    fields :instructions
    association :recipe_ingredients, blueprint: RecipeIngredientBlueprint, name: :ingredients
  end

  view :admin do
    include_view :detail
    fields :active, :created_at, :updated_at
  end
end
