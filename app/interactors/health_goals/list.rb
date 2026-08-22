module HealthGoals
  class List
    attr_reader :health_goals, :error

    def self.call
      new.call
    end

    def initialize
      @health_goals = []
      @error = nil
    end

    def call
      @health_goals = HealthGoal.active.ordered
      self
    rescue StandardError => e
      @error = "Error listing health goals: #{e.message}"
      self
    end

    def success?
      @error.nil?
    end
  end
end
