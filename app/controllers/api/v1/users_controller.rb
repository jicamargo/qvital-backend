module Api
  module V1
    class UsersController < BaseController
      # PATCH /api/v1/users/me
      def update_me
        result = ::Users::UpdateProfile.call(user: current_user, attributes: profile_params)

        if result.success?
          render json: { user: JSON.parse(UserBlueprint.render(result.user)) }, status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Users update_me error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def profile_params
        params.permit(:name, :last_name, :phone, address: [:street, :city, :state, :zipCode]).to_h
      end
    end
  end
end
