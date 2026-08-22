class BodyRegion < ApplicationRecord
  belongs_to :parent, class_name: "BodyRegion", optional: true
  has_many :children, class_name: "BodyRegion", foreign_key: :parent_id, dependent: :nullify
  has_many :body_emotion_insights, dependent: :restrict_with_error

  enum :body_system, {
    cabeza_cuello: 0,
    torax: 1,
    digestivo: 2,
    columna_espalda: 3,
    extremidades: 4,
    piel: 5,
    sistema_reproductivo: 6,
    general_energetico: 7
  }

  validates :name, presence: true, uniqueness: true
  validates :body_system, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:body_system, :display_order, :name) }
end
