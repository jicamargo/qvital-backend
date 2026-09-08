module Api
  module V1
    # Endpoint público (sin autenticación): captura leads del formulario de
    # /evaluacion antes de que el visitante tenga cuenta. Es la puerta de
    # entrada de crecimiento del producto — no debe requerir sesión.
    class EvaluationLeadsController < ApplicationController
      # POST /api/v1/evaluation_leads
      def create
        result = ::EvaluationLeads::Create.call(params: evaluation_lead_params)

        if result.success?
          render json: JSON.parse(EvaluationLeadBlueprint.render(result.lead)), status: :created
        else
          render json: { error: result.error || 'No se pudo guardar la evaluación', details: result.errors }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Evaluation leads create error: #{e.class.name} - #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end

      private

      def evaluation_lead_params
        params.permit(:email, :age, :sex, :weight_kg, :height_cm, :waist_cm, :activity_level, :goal, :emotional_state)
      end
    end
  end
end
