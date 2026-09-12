module Habits
  class Archive
    attr_reader :error

    def self.call(user:, habit_id:)
      new(user:, habit_id:).call
    end

    def initialize(user:, habit_id:)
      @user = user
      @habit_id = habit_id
      @error = nil
    end

    def call
      habit = @user.user_habits.active.find_by(id: @habit_id)
      return failure("Habit not found") unless habit

      habit.update(active: false)
      self
    rescue StandardError => e
      @error = "Error archiving habit: #{e.message}"
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
