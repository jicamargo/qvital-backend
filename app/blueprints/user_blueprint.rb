class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :supabase_uid, :role, :name, :last_name, :hlf_id, :phone, :address

  field :level_id

  association :level, blueprint: LevelBlueprint

  # Computado (respeta premium_expires_at) — ver User#premium?
  field :premium_active do |user|
    user.premium?
  end

  # Incluir app_metadata con el role de Rails (similar a estructura de Supabase)
  field :app_metadata do |user|
    {
      role: user.role
    }
  end

  view :admin do
    fields :premium_expires_at, :created_at, :updated_at

    field :account_status do |user|
      user.supabase_uid.present? ? 'activo' : 'pendiente'
    end
  end
end
