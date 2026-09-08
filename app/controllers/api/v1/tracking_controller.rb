module Api
  module V1
    class TrackingController < BaseController
      # GET /api/v1/tracking
      def index
        result = ::Tracking::List.call(user: current_user)

        if result.success?
          entries_json = JSON.parse(TrackingEntryBlueprint.render(result.entries))
          render json: { entries: entries_json }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Tracking index error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      # POST /api/v1/tracking
      # Crea el registro de hoy, o lo actualiza si ya existe (un solo
      # registro por día — ver Tracking::Upsert).
      def create
        result = ::Tracking::Upsert.call(user: current_user, params: create_params)

        if result.success?
          status = result.created ? :created : :ok
          render json: { entry: JSON.parse(TrackingEntryBlueprint.render(result.entry)) }, status: status
        elsif result.error
          render json: { error: result.error }, status: :unprocessable_entity
        else
          render json: { error: "Validation error", details: result.errors }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Tracking create error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      # GET /api/v1/tracking/prefill
      def prefill
        result = ::Tracking::Prefill.call(user: current_user)

        if result.success?
          render json: {
            is_first_entry: result.is_first_entry,
            evaluation_lead: result.evaluation_lead ? JSON.parse(EvaluationLeadPrefillBlueprint.render(result.evaluation_lead)) : nil,
            today_entry: result.today_entry ? JSON.parse(TrackingEntryBlueprint.render(result.today_entry)) : nil
          }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Tracking prefill error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def create_params
        params.permit(:weight_kg, :waist_cm, :mood, :energy_level, :habits_completed)
      end
    end
  end
end
