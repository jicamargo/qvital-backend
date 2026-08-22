module Api
  module V1
    module CoachVirtual
      class BodyRegionsController < BaseController
        before_action :authorize_premium!

        # GET /api/v1/coach_virtual/body_regions
        def index
          result = ::CoachVirtual::BodyRegions::List.call

          if result.success?
            body_regions_json = JSON.parse(BodyRegionBlueprint.render(result.body_regions))
            render json: { body_regions: body_regions_json }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Coach virtual body regions index error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        private

        def authorize_premium!
          unless current_user&.premium?
            render json: { error: 'Se requiere membresía premium' }, status: :forbidden and return
          end
        end
      end
    end
  end
end
