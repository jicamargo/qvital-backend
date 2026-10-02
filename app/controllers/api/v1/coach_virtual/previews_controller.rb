module Api
  module V1
    module CoachVirtual
      class PreviewsController < BaseController
        # GET /api/v1/coach_virtual/previews/:body_region_id
        # Demo gratuita (cualquier usuaria autenticada): contenido limitado de la ficha.
        def show
          result = ::CoachVirtual::Insights::Preview.call(user: current_user, body_region_id: params[:body_region_id])

          if result.success?
            render json: { preview: result.preview }, status: :ok
          elsif result.not_found
            render json: { error: result.error }, status: :not_found
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach virtual preview show error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end
      end
    end
  end
end
