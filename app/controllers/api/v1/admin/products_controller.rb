module Api
  module V1
    module Admin
      class ProductsController < BaseController
        before_action :authorize_admin!

        def index
          result = ::Admin::Products::List.call(params: index_params)

          if result.success?
            render json: ProductBlueprint.render(result.products, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        def show
          result = ::Admin::Products::Show.call(id: params[:id])

          if result.success?
            render json: ProductBlueprint.render(result.product, view: :admin), status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        end

        def create
          result = ::Admin::Products::Create.call(params: product_params)

          if result.success?
            render json: ProductBlueprint.render(result.product, view: :admin), status: :created
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        def update
          result = ::Admin::Products::Update.call(id: params[:id], params: product_params)

          if result.success?
            render json: ProductBlueprint.render(result.product, view: :admin), status: :ok
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        end

        def destroy
          result = ::Admin::Products::Destroy.call(id: params[:id])

          if result.success?
            head :no_content
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden and return
          end
        end

        def index_params
          params.permit(:category_id, :search, :active)
        end

        def product_params
          params.require(:product).permit(
            :name,
            :description,
            :image_url,
            :image_path,
            :sku,
            :pv,
            :category_id,
            :active,
            prices: {}
          )
        end
      end
    end
  end
end

