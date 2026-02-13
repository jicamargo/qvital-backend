module Api
  module V1
    class AuthController < ApplicationController
      def sync
        token = extract_token
        return render_unauthorized('No token') unless token

        result = Auth::SyncUser.call(token: token)

        if result.success?
          user_json = JSON.parse(UserBlueprint.render(result.user))
          render json: { user: user_json }, status: :ok
        else
          render json: { error: result.error }, status: :unauthorized
        end
      rescue StandardError => e
        Rails.logger.error "Auth sync error: #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end

      private

      def extract_token
        request.headers['Authorization']&.split(' ')&.last
      end

      def render_unauthorized(message)
        render json: { error: message }, status: :unauthorized
      end
    end
  end
end
