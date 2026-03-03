module Api
  module V1
    class AuthController < ApplicationController
      include Authenticatable

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

      # Endpoint de debug para forzar actualización de metadata
      def update_metadata
        authenticate_user!
        
        result = Auth::UpdateSupabaseMetadata.call(user: current_user)
        
        if result.success?
          render json: { 
            message: 'Metadata updated successfully',
            user_id: current_user.id,
            role: current_user.role,
            supabase_uid: current_user.supabase_uid
          }, status: :ok
        else
          render json: { 
            error: result.error,
            user_id: current_user.id,
            role: current_user.role,
            supabase_uid: current_user.supabase_uid,
            has_service_key: ENV['SUPABASE_SERVICE_ROLE_KEY'].present?,
            has_supabase_url: ENV['SUPABASE_URL'].present?
          }, status: :unprocessable_entity
        end
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
