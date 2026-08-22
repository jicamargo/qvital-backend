module Admin
  module HealthGoals
    class Create
      attr_reader :health_goal, :error, :errors

      def self.call(params:)
        new(params: params).call
      end

      def initialize(params:)
        @params = params || {}
        @health_goal = nil
        @error = nil
        @errors = {}
      end

      def call
        @health_goal = HealthGoal.new(@params)

        unless @health_goal.save
          @errors = @health_goal.errors.to_hash
          return failure("No se pudo crear el objetivo de salud")
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error creating health goal: #{e.message}"
        failure("Error inesperado creando el objetivo de salud")
      end

      def success?
        @error.nil? && @health_goal&.persisted?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end
