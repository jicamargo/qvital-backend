module Api
  module V1
    class HabitsController < BaseController
      # GET /api/v1/habits
      def index
        result = ::Habits::List.call(user: current_user, week_start: params[:week_start])

        if result.success?
          habits_json = JSON.parse(
            UserHabitBlueprint.render(result.habits, completions_by_habit_id: result.completions_by_habit_id)
          )
          render json: {
            week_start: result.week_start,
            week_end: result.week_end,
            habits: habits_json
          }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Habits index error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      # POST /api/v1/habits
      def create
        result = ::Habits::Create.call(user: current_user, params: create_params)

        if result.success?
          habit_json = JSON.parse(UserHabitBlueprint.render(result.habit, completions_by_habit_id: {}))
          render json: { habit: habit_json }, status: :created
        elsif result.errors.present?
          render json: { error: "Validation error", details: result.errors }, status: :unprocessable_entity
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Habits create error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      # DELETE /api/v1/habits/:id (archiva, no borra físicamente)
      def destroy
        result = ::Habits::Archive.call(user: current_user, habit_id: params[:id])

        if result.success?
          head :no_content
        else
          render json: { error: result.error }, status: :not_found
        end
      rescue StandardError => e
        Rails.logger.error "Habits destroy error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      # POST /api/v1/habits/:id/toggle_completion
      def toggle_completion
        result = ::Habits::ToggleCompletion.call(user: current_user, habit_id: params[:id], date: params[:date])

        if result.success?
          render json: { habit_id: params[:id].to_i, date: params[:date], completed: result.completed }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Habits toggle_completion error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def create_params
        params.permit(:name)
      end
    end
  end
end
