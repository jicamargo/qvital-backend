class HabitCompletion < ApplicationRecord
  belongs_to :user_habit

  validates :completed_on, presence: true, uniqueness: { scope: :user_habit_id }
end
