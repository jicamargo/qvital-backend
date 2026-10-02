class BodyRegion < ApplicationRecord
  # Enfoques temáticos que cruzan varios body_system (filtro de la Brújula).
  FOCUS_AREAS = %w[control_peso].freeze

  # Áreas del mapa corporal (silueta) a las que pertenece cada zona; el frontend las dibuja.
  BODY_MAP_AREAS = %w[cabeza_cuello pecho abdomen zona_pelvica brazos_manos piernas_pies espalda_alta espalda_baja todo_cuerpo].freeze

  belongs_to :parent, class_name: "BodyRegion", optional: true
  has_many :children, class_name: "BodyRegion", foreign_key: :parent_id, dependent: :nullify
  has_many :body_emotion_insights, dependent: :restrict_with_error
  has_many :coach_demo_views, dependent: :delete_all

  enum :body_system, {
    cabeza_cuello: 0,
    torax: 1,
    digestivo: 2,
    columna_espalda: 3,
    extremidades: 4,
    piel: 5,
    sistema_reproductivo: 6,
    general_energetico: 7,
    peso_y_figura: 8
  }

  validates :name, presence: true, uniqueness: true
  validates :body_system, presence: true
  validates :illustration_ref, inclusion: { in: BODY_MAP_AREAS }, allow_nil: true
  before_validation { self.illustration_ref = illustration_ref.presence }
  validate :focus_areas_are_known

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:body_system, :display_order, :name) }
  scope :with_focus_area, ->(focus_area) { where("focus_areas @> ?", [ focus_area ].to_json) }

  private

  def focus_areas_are_known
    unless focus_areas.is_a?(Array) && (focus_areas - FOCUS_AREAS).empty?
      errors.add(:focus_areas, "contiene valores no permitidos (permitidos: #{FOCUS_AREAS.join(', ')})")
    end
  end
end
