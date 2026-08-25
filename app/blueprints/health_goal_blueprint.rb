class HealthGoalBlueprint < Blueprinter::Base
  identifier :id

  fields :key, :name, :description, :icon, :color, :position

  view :admin do
    fields :active, :created_at, :updated_at
  end
end
