module Admin
  module HealthGoals
    class List
      attr_reader :health_goals, :error

      def self.call(params: {})
        new(params: params).call
      end

      def initialize(params: {})
        @params = params || {}
        @health_goals = []
        @error = nil
      end

      def call
        scope = HealthGoal.all
        scope = scope.where(active: to_bool(@params[:active])) if @params.key?(:active)

        @health_goals = scope.ordered
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

      def to_bool(value)
        return true if value == true || value.to_s.downcase == "true"
        return false if value == false || value.to_s.downcase == "false"
        nil
      end
    end
  end
end
