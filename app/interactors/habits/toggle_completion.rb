module Habits
  class ToggleCompletion
    attr_reader :completed, :error

    def self.call(user:, habit_id:, date:)
      new(user:, habit_id:, date:).call
    end

    def initialize(user:, habit_id:, date:)
      @user = user
      @habit_id = habit_id
      @date = date
      @completed = false
      @error = nil
    end

    def call
      habit = @user.user_habits.active.find_by(id: @habit_id)
      return failure("Habit not found") unless habit

      parsed_date = begin
        Date.parse(@date.to_s)
      rescue ArgumentError, TypeError
        nil
      end
      return failure("Invalid date") unless parsed_date

      # Decisión confirmada (docs/requirements/mi-plan-habitos-semanales.md §6.3):
      # solo se puede marcar hoy o días pasados de la semana actual, nunca días futuros.
      markable_range = Date.current.beginning_of_week..Date.current
      return failure("Solo puedes marcar hoy o días anteriores de esta semana.") unless markable_range.cover?(parsed_date)

      existing = habit.habit_completions.find_by(completed_on: parsed_date)
      if existing
        existing.destroy
        @completed = false
      else
        habit.habit_completions.create!(completed_on: parsed_date)
        @completed = true
      end

      self
    rescue StandardError => e
      @error = "Error toggling habit completion: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end

    private

    def failure(message)
      @error = message
      self
    end
  end
end
