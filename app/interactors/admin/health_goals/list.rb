module Admin
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
        @health_goals = HealthGoal.ordered
        self
      rescue StandardError => e
        Rails.logger.error "Error listing health goals (admin): #{e.message}"
        failure("Error inesperado cargando los objetivos de salud")
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
end
