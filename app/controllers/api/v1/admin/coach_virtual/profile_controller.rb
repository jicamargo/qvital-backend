module Api
  module V1
    module Admin
      module CoachVirtual
        class ProfileController < BaseController
          before_action :authorize_admin!

          # GET /api/v1/admin/coach_virtual/profile
          def show
            result = ::CoachVirtual::Profile::Show.call

            if result.success?
              render json: VirtualCoachProfileBlueprint.render(result.profile, view: :admin), status: :ok
            else
              render json: { error: result.error }, status: :not_found
            end
          end

          # PATCH /api/v1/admin/coach_virtual/profile
          def update
            current = ::VirtualCoachProfile.current
            unless current
              render json: { error: 'No hay una Coach Virtual activa configurada' }, status: :not_found and return
            end

            result = ::Admin::CoachVirtual::Profile::Update.call(id: current.id, params: profile_params)

            if result.success?
              render json: VirtualCoachProfileBlueprint.render(result.profile, view: :admin), status: :ok
            else
              render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
            end
          end

          private

          def authorize_admin!
            unless current_user&.admin?
              render json: { error: 'Forbidden' }, status: :forbidden and return
            end
          end

          def profile_params
            params.require(:virtual_coach_profile).permit(:display_name, :gender, :specialty_description, :avatar_url, :active, tone_profile: {})
          end
        end
      end
    end
  end
end
