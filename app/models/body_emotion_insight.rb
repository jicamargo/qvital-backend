class BodyEmotionInsight < ApplicationRecord
  belongs_to :body_region
  has_many :coach_consultation_entries, dependent: :nullify

  enum :severity_flag, { informativo: 0, sugerir_acompanamiento_profesional: 1 }, default: :informativo
  enum :status, { borrador: 0, publicado: 1, archivado: 2 }, default: :borrador

  validates :symptom_pattern, presence: true
  validates :emotional_theme, presence: true
  validates :narrative_explanation, presence: true
  validates :integration_guidance, presence: true

  scope :published, -> { where(status: :publicado) }
end
