class TrackingEntry < ApplicationRecord
  MOODS = %w[excelente bueno regular malo].freeze
  ENERGY_LEVELS = %w[alta media baja].freeze

  belongs_to :user

  before_validation :default_recorded_on, on: :create

  validates :recorded_on, presence: true, uniqueness: { scope: :user_id }
  validates :weight_kg, presence: true, numericality: { greater_than: 0, less_than: 500 }
  validates :waist_cm, numericality: { greater_than: 0, less_than: 300 }, allow_nil: true
  validates :mood, inclusion: { in: MOODS }, allow_nil: true
  validates :energy_level, inclusion: { in: ENERGY_LEVELS }, allow_nil: true
  validates :habits_completed, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  scope :most_recent_first, -> { order(created_at: :desc) }

  private

  def default_recorded_on
    self.recorded_on ||= Date.current
  end
end
