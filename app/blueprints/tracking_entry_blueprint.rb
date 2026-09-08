class TrackingEntryBlueprint < Blueprinter::Base
  identifier :id

  fields :weight_kg, :waist_cm, :mood, :energy_level, :habits_completed, :recorded_on, :created_at
end
