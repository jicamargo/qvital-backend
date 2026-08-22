module Api
  module V1
    module Admin
      class UsersController < BaseController
        before_action :authorize_admin!

        # GET /api/v1/admin/users
        def index
          result = ::Admin::Users::List.call(params: index_params)

          if result.success?
            render json: UserBlueprint.render(result.users, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin users index error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: 'Forbidden' }, status: :forbidden and return
          end
        end

        def index_params
          params.permit(:role, :search)
        end
      end
    end
  end
end
