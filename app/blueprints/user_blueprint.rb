class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :supabase_uid, :role, :nombre, :hlf_id

  field :level_id

  association :level, blueprint: LevelBlueprint
end
