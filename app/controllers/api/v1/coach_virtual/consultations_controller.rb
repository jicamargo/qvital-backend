module Api
  module V1
    module CoachVirtual
      class ConsultationsController < BaseController
        before_action :authorize_premium!

        # GET /api/v1/coach_virtual/consultations
        def index
          result = ::CoachVirtual::Consultations::List.call(user: current_user)

          if result.success?
            consultations_json = JSON.parse(CoachConsultationBlueprint.render(result.consultations))
            render json: { consultations: consultations_json }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations index error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # GET /api/v1/coach_virtual/consultations/:id
        def show
          result = ::CoachVirtual::Consultations::Show.call(user: current_user, consultation_id: params[:id])

          if result.success?
            render_consultation(result.consultation)
          else
            render json: { error: result.error }, status: :not_found
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations show error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # POST /api/v1/coach_virtual/consultations
        def create
          result = ::CoachVirtual::Consultations::Start.call(user: current_user)

          if result.success?
            render_consultation(result.consultation, status: :created)
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations create error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # POST /api/v1/coach_virtual/consultations/:id/close
        def close
          result = ::CoachVirtual::Consultations::Close.call(user: current_user, consultation_id: params[:id])

          if result.success?
            render_consultation(result.consultation)
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations close error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # POST /api/v1/coach_virtual/consultations/:id/zone_selections
        def zone_selections
          result = ::CoachVirtual::Consultations::RegisterZoneSelection.call(
            user: current_user,
            consultation_id: params[:id],
            body_region_id: zone_selection_params[:body_region_id],
            user_input: zone_selection_params[:user_input]
          )

          if result.success?
            render_consultation(result.consultation)
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations zone_selections error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # POST /api/v1/coach_virtual/consultations/:id/reflection_answers
        def reflection_answers
          result = ::CoachVirtual::Consultations::RegisterReflectionAnswer.call(
            user: current_user,
            consultation_id: params[:id],
            question: reflection_answer_params[:question],
            answer: reflection_answer_params[:answer]
          )

          if result.success?
            render_consultation(result.consultation)
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach consultations reflection_answers error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        private

        # `result.consultation` no siempre trae los entries eager-loaded (ej.
        # tras Start/Close/RegisterZoneSelection), así que recargamos vía
        # Show para asegurar el shape con :with_entries siempre completo.
        def render_consultation(consultation, status: :ok)
          full = ::CoachVirtual::Consultations::Show.call(user: current_user, consultation_id: consultation.id).consultation
          consultation_json = JSON.parse(CoachConsultationBlueprint.render(full, view: :with_entries))
          render json: { consultation: consultation_json }, status: status
        end

        def authorize_premium!
          unless current_user&.premium?
            render json: { error: 'Se requiere membresía premium' }, status: :forbidden and return
          end
        end

        def zone_selection_params
          params.require(:zone_selection).permit(:body_region_id, :user_input)
        end

        def reflection_answer_params
          params.require(:reflection_answer).permit(:question, :answer)
        end
      end
    end
  end
end
