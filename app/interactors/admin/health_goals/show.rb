module Admin
  module HealthGoals
    class Show
      attr_reader :health_goal, :error

      def self.call(id:)
        new(id: id).call
      end

      def initialize(id:)
        @id = id
        @health_goal = nil
        @error = nil
      end

      def call
        @health_goal = HealthGoal.find_by(id: @id)
        return failure("Health goal not found") unless @health_goal

        self
      rescue StandardError => e
        Rails.logger.error "Error showing health goal (admin): #{e.message}"
        failure("Error inesperado cargando el objetivo de salud")
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
