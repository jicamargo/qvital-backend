class User < ApplicationRecord
  include Searchable

  belongs_to :level, optional: true
  has_many :coach_consultations, dependent: :destroy
  has_many :user_feature_usages, dependent: :destroy
  has_many :tracking_entries, dependent: :destroy
  has_many :user_habits, dependent: :destroy

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

  searchable_by :email, :name, :last_name

  def admin?
    role == 'admin'
  end

  def cliente?
    role == 'cliente'
  end

  # Placeholder mínimo mientras no exista el sistema real de membresías/suscripciones
  # (ver docs/requirements/coach-cuerpo-emocion-sdd.md §9.1 en qvital-frontend).
  def premium?
    premium_active? && (premium_expires_at.nil? || premium_expires_at.future?)
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
