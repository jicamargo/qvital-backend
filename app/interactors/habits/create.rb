module Habits
  class Create
    attr_reader :habit, :error, :errors

    def self.call(user:, params:)
      new(user:, params:).call
    end

    def initialize(user:, params:)
      @user = user
      @params = params || {}
      @habit = nil
      @error = nil
      @errors = {}
    end

    def call
      return failure("User is required") unless @user

      if @user.user_habits.active.count >= UserHabit::MAX_ACTIVE_PER_USER
        return failure(
          "Ya tienes el máximo de #{UserHabit::MAX_ACTIVE_PER_USER} hábitos activos. Archiva uno para agregar otro."
        )
      end

      next_position = @user.user_habits.active.maximum(:position).to_i + 1
      @habit = @user.user_habits.new(name: @params[:name], position: next_position, active: true)

      @errors = @habit.errors.to_hash unless @habit.save

      self
    rescue StandardError => e
      @error = "Error creating habit: #{e.message}"
      self
    end

    def success?
      @error.nil? && @habit&.persisted?
    end

    private

    def failure(message)
      @error = message
      self
    end
  end
end
