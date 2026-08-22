class HealthGoalBlueprint < Blueprinter::Base
  identifier :id

  fields :key, :name, :description, :icon, :color, :position
end
