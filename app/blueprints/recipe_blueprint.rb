class RecipeBlueprint < Blueprinter::Base
  identifier :id

  fields :title, :slug, :description, :servings, :prep_time_minutes, :difficulty, :image_url,
         :recipe_type, :calories, :protein_g, :carbs_g, :fat_g, :fiber_g

  association :health_goals, blueprint: HealthGoalBlueprint

  view :detail do
    fields :instructions, :tips, :source
    association :recipe_ingredients, blueprint: RecipeIngredientBlueprint, name: :ingredients
  end

  view :admin do
    include_view :detail
    fields :active, :image_path, :created_at, :updated_at
  end
end
