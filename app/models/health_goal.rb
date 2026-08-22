class HealthGoal < ApplicationRecord
  has_many :product_health_goals, dependent: :destroy
  has_many :products, through: :product_health_goals

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :icon, presence: true
  validates :color, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
