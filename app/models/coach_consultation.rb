class CoachConsultation < ApplicationRecord
  belongs_to :user
  belongs_to :virtual_coach_profile
  has_many :coach_consultation_entries, -> { order(:sequence) }, dependent: :destroy, inverse_of: :coach_consultation

  enum :status, { abierta: 0, cerrada: 1 }, default: :abierta

  validates :started_at, presence: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :recent_first, -> { order(started_at: :desc) }

  # Resumen liviano para el listado de historial (sin traer todos los
  # entries al frontend). Requiere `coach_consultation_entries: :body_region`
  # precargado (ver CoachVirtual::Consultations::List) para evitar N+1.
  def body_regions_summary
    coach_consultation_entries
      .select { |entry| entry.zona_seleccionada? }
      .filter_map(&:body_region)
      .uniq
      .map { |region| { id: region.id, name: region.name } }
  end
end
