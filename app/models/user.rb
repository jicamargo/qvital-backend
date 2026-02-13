class User < ApplicationRecord
  belongs_to :level, optional: true

  validates :email, presence: true, uniqueness: true
  validates :role, presence: true, inclusion: { in: %w[admin cliente] }
  validates :supabase_uid, uniqueness: true, allow_nil: true
  validates :hlf_id, uniqueness: true, allow_nil: true

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
end
