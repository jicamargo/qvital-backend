class UserFeatureUsage < ApplicationRecord
  FEATURE_KEYS = %w[marketplace mi-plan seguimiento coach-ia recetas habitos retos].freeze

  belongs_to :user

  validates :feature_key, presence: true, inclusion: { in: FEATURE_KEYS }
  validates :feature_key, uniqueness: { scope: :user_id }
  validates :last_used_at, presence: true
end
