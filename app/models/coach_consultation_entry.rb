class CoachConsultationEntry < ApplicationRecord
  belongs_to :coach_consultation, inverse_of: :coach_consultation_entries
  belongs_to :body_region, optional: true
  belongs_to :body_emotion_insight, optional: true

  enum :entry_type, {
    zona_seleccionada: 0,
    sintoma_descrito_usuario: 1,
    ficha_mostrada: 2,
    respuesta_reflexion_usuario: 3,
    mensaje_libre: 4
  }

  validates :sequence, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :entry_type, presence: true
end
