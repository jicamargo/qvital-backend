class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :supabase_uid, :role, :nombre, :hlf_id

  field :level_id

  association :level, blueprint: LevelBlueprint

  # Incluir app_metadata con el role de Rails (similar a estructura de Supabase)
  field :app_metadata do |user|
    {
      role: user.role
    }
  end
end
