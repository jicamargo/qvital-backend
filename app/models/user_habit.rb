class UserHabit < ApplicationRecord
  MAX_ACTIVE_PER_USER = 5

  belongs_to :user
  has_many :habit_completions, dependent: :destroy

  validates :name, presence: true, length: { maximum: 60 }
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }, if: :active?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
end
