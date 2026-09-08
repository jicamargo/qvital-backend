module Api
  module V1
    # Configuración pública para cualquier usuario autenticado — hoy solo el
    # umbral de compra para Premium (ver docs/endpoints/api-v1-settings.md),
    # que la pantalla /premium necesita mostrar sin ser admin. Reutiliza el
    # mismo interactor que Admin::SettingsController#show; la diferencia es
    # que este controller no exige rol admin.
    class SettingsController < BaseController
      # GET /api/v1/settings
      def show
        result = ::Admin::Settings::Show.call

        if result.success?
          render json: JSON.parse(AppSettingBlueprint.render(result.setting)), status: :ok
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Settings show error: #{e.class.name} - #{e.message}"
        render json: { error: "Internal server error" }, status: :internal_server_error
      end
    end
  end
end
