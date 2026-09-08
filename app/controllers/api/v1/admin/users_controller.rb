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

        # GET /api/v1/admin/users/:id
        def show
          result = ::Admin::Users::Show.call(id: params[:id])

          if result.success?
            render json: UserBlueprint.render(result.user, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        rescue StandardError => e
          Rails.logger.error "Admin users show error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # PATCH/PUT /api/v1/admin/users/:id
        def update
          result = ::Admin::Users::Update.call(id: params[:id], params: user_params)

          if result.success?
            render json: UserBlueprint.render(result.user, view: :admin), status: :ok
          elsif result.error == "User not found"
            render json: { error: result.error }, status: :not_found
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin users update error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # DELETE /api/v1/admin/users/:id
        def destroy
          result = ::Admin::Users::Destroy.call(id: params[:id])

          if result.success?
            head :no_content
          elsif result.error == "User not found"
            render json: { error: result.error }, status: :not_found
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin users destroy error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
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

        def user_params
          params.require(:user).permit(:name, :last_name, :phone, :role, :level_id, :premium_active, :premium_expires_at)
        end
      end
    end
  end
end
