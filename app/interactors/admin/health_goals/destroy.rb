module Admin
  module HealthGoals
    class Destroy
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

        # Soft delete: desactivar en vez de borrar, para no romper productos
        # ya taggeados con este objetivo (ver fase3-personalizacion-objetivos-salud.md §3.1).
        @health_goal.update(active: false)
        self
      rescue StandardError => e
        Rails.logger.error "Error destroying health goal: #{e.message}"
        failure("Error inesperado eliminando el objetivo de salud")
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
