class User < ApplicationRecord
  belongs_to :level, optional: true

  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[admin cliente] }
  validates :supabase_uid, uniqueness: true, allow_nil: true
  validates :hlf_id, uniqueness: true, allow_nil: true

  # Callback para sincronizar role con Supabase metadata cuando cambia
  after_update :sync_role_to_supabase, if: :saved_change_to_role?

  # Scopes útiles
  scope :admins, -> { where(role: 'admin') }
  scope :clientes, -> { where(role: 'cliente') }
  scope :active, -> { where.not(supabase_uid: nil) }

  def admin?
    role == 'admin'
  end

  def cliente?
    role == 'cliente'
  end

  private

  def sync_role_to_supabase
    return unless supabase_uid.present?

    # Actualizar metadata en Supabase de forma asíncrona para no bloquear la respuesta
    # En producción, podrías usar ActiveJob aquí
    result = Auth::UpdateSupabaseMetadata.call(user: self)
    
    unless result.success?
      Rails.logger.warn "Failed to sync role to Supabase for user #{id}: #{result.error}"
    end
  end
end
