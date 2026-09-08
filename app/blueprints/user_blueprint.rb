class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :email, :supabase_uid, :role, :name, :last_name, :hlf_id, :phone, :address

  field :level_id

  association :level, blueprint: LevelBlueprint

  # Computado (respeta premium_expires_at) — ver User#premium?
  field :premium_active do |user|
    user.premium?
  end

  # Un usuario sí puede ver cuándo expira SU PROPIO Premium (no es un dato
  # admin-only) — la pantalla /premium lo usa para mostrar "activo hasta...".
  field :premium_expires_at

  # Incluir app_metadata con el role de Rails (similar a estructura de Supabase)
  field :app_metadata do |user|
    {
      role: user.role
    }
  end

  # Usado para ordenar "Acceso Rápido" del dashboard por uso reciente (sub-fase 3.7)
  field :feature_usages do |user|
    user.user_feature_usages.map { |usage| { feature_key: usage.feature_key, last_used_at: usage.last_used_at } }
  end

  view :admin do
    fields :created_at, :updated_at

    field :account_status do |user|
      user.supabase_uid.present? ? 'activo' : 'pendiente'
    end
  end
end
