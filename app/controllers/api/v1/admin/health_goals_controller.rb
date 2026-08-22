module Api
  module V1
    module Admin
      class HealthGoalsController < BaseController
        before_action :authorize_admin!

        # GET /api/v1/admin/health_goals
        def index
          result = ::Admin::HealthGoals::List.call

          if result.success?
            render json: HealthGoalBlueprint.render(result.health_goals, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        # GET /api/v1/admin/health_goals/:id
        def show
          result = ::Admin::HealthGoals::Show.call(id: params[:id])

          if result.success?
            render json: HealthGoalBlueprint.render(result.health_goal, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        end

        # POST /api/v1/admin/health_goals
        def create
          result = ::Admin::HealthGoals::Create.call(params: health_goal_params)

          if result.success?
            render json: HealthGoalBlueprint.render(result.health_goal, view: :admin), status: :created
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        # PATCH /api/v1/admin/health_goals/:id
        def update
          result = ::Admin::HealthGoals::Update.call(id: params[:id], params: health_goal_params)

          if result.success?
            render json: HealthGoalBlueprint.render(result.health_goal, view: :admin), status: :ok
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        # DELETE /api/v1/admin/health_goals/:id
        def destroy
          result = ::Admin::HealthGoals::Destroy.call(id: params[:id])

          if result.success?
            head :no_content
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden and return
          end
        end

        def health_goal_params
          params.require(:health_goal).permit(:key, :name, :description, :icon, :color, :position, :active)
        end
      end
    end
  end
end
