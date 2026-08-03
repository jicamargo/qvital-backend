module Api
  module V1
    module CoachVirtual
      class ProfileController < BaseController
        # GET /api/v1/coach_virtual/profile
        def show
          result = ::CoachVirtual::Profile::Show.call

          if result.success?
            profile_json = JSON.parse(VirtualCoachProfileBlueprint.render(result.profile))
            render json: { profile: profile_json }, status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        rescue StandardError => e
          Rails.logger.error "Coach virtual profile show error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end
      end
    end
  end
end
