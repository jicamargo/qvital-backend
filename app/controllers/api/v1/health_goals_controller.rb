module Api
  module V1
    class HealthGoalsController < BaseController
      # GET /api/v1/health_goals
      def index
        result = ::HealthGoals::List.call

        if result.success?
          health_goals_json = JSON.parse(HealthGoalBlueprint.render(result.health_goals))
          render json: { health_goals: health_goals_json }, status: :ok
        else
          render json: { error: result.error || 'Unable to load health goals' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Health goals index error: #{e.class.name} - #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
end
