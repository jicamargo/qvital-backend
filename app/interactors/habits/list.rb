module Habits
  class List
    attr_reader :habits, :completions_by_habit_id, :week_start, :week_end, :error

    def self.call(user:, week_start: nil)
      new(user:, week_start:).call
    end

    def initialize(user:, week_start:)
      @user = user
      reference_date = week_start.present? ? (Date.parse(week_start.to_s) rescue Date.current) : Date.current
      @week_start = reference_date.beginning_of_week
      @week_end = @week_start.end_of_week
      @habits = []
      @completions_by_habit_id = {}
      @error = nil
    end

    def call
      return failure("User is required") unless @user

      @habits = @user.user_habits.active.ordered

      completions = HabitCompletion
        .where(user_habit_id: @habits.map(&:id))
        .where(completed_on: @week_start..@week_end)

      @completions_by_habit_id = completions.group_by(&:user_habit_id)
        .transform_values { |rows| rows.map(&:completed_on) }

      self
    rescue StandardError => e
      @error = "Error listing habits: #{e.message}"
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
