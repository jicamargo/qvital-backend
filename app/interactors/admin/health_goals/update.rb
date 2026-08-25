module Admin
  module HealthGoals
    class Update
      attr_reader :health_goal, :error, :errors

      def self.call(id:, params:)
        new(id: id, params: params).call
      end

      def initialize(id:, params:)
        @id = id
        @params = params || {}
        @health_goal = nil
        @error = nil
        @errors = {}
      end

      def call
        @health_goal = HealthGoal.find_by(id: @id)
        return failure("Health goal not found") unless @health_goal

        unless @health_goal.update(@params)
          @errors = @health_goal.errors.to_hash
          return failure("No se pudo actualizar el objetivo de salud")
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error updating health goal: #{e.message}"
        failure("Error inesperado actualizando el objetivo de salud")
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
