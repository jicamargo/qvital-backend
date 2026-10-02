class BodyEmotionInsight < ApplicationRecord
  belongs_to :body_region
  has_many :coach_consultation_entries, dependent: :nullify

  enum :severity_flag, { informativo: 0, sugerir_acompanamiento_profesional: 1 }, default: :informativo
  enum :status, { borrador: 0, publicado: 1, archivado: 2 }, default: :borrador

  validates :symptom_pattern, presence: true
  validates :emotional_theme, presence: true
  validates :narrative_explanation, presence: true
  validates :integration_guidance, presence: true
  validate :practices_are_valid

  MAX_PRACTICES = 3
  PRACTICE_LIMITS = { title: 50, description: 140 }.freeze

  scope :published, -> { where(status: :publicado) }

  private

  def practices_are_valid
    unless practices.is_a?(Array)
      errors.add(:practices, "debe ser una lista")
      return
    end

    errors.add(:practices, "no puede tener más de #{MAX_PRACTICES} prácticas") if practices.size > MAX_PRACTICES
    errors.add(:practices, "tiene una práctica inválida") unless practices.all? { |practice| valid_practice?(practice) }
  end

  def valid_practice?(practice)
    practice.is_a?(Hash) &&
      practice.keys.map(&:to_s).sort == PRACTICE_LIMITS.keys.map(&:to_s).sort &&
      PRACTICE_LIMITS.all? do |key, max|
        value = practice[key.to_s] || practice[key]
        value.is_a?(String) && value == value.strip && value.length.between?(1, max)
      end
  end
end
