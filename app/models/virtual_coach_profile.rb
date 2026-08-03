class VirtualCoachProfile < ApplicationRecord
  has_many :coach_consultations, dependent: :restrict_with_error

  enum :gender, { femenino: 0, masculino: 1, neutro: 2 }, default: :femenino

  validates :display_name, presence: true
  validates :specialty_description, presence: true

  scope :active, -> { where(active: true) }

  def self.current
    active.first
  end
end
