module Api
  module V1
    module Admin
      # Niveles de precio (Cliente, Cliente VIP, ...) para el formulario de productos.
      class LevelsController < BaseController
        before_action :authorize_admin!

        def index
          render json: LevelBlueprint.render(Level.order(:priority)), status: :ok
        end

        private

        def authorize_admin!
          return if current_user&.admin?

          render json: { error: "Forbidden" }, status: :forbidden
        end
      end
    end
  end
end
