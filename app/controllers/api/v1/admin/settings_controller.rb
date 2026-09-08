module Api
  module V1
    module Admin
      class SettingsController < BaseController
        before_action :authorize_admin!

        # GET /api/v1/admin/settings
        def show
          result = ::Admin::Settings::Show.call

          if result.success?
            render json: JSON.parse(AppSettingBlueprint.render(result.setting)), status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin settings show error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # PATCH /api/v1/admin/settings
        def update
          result = ::Admin::Settings::Update.call(params: setting_params)

          if result.success?
            render json: JSON.parse(AppSettingBlueprint.render(result.setting)), status: :ok
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin settings update error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden and return
          end
        end

        def setting_params
          params.require(:setting).permit(:premium_purchase_threshold)
        end
      end
    end
  end
end
