module Api
  module V1
    class ProductsController < BaseController
      # GET /api/v1/products
      def index
        result = Products::ListForUser.call(user: current_user)

        if result.success?
          products_json = JSON.parse(
            ProductBlueprint.render(result.products, level_id: current_user.level_id)
          )

          render json: { products: products_json }, status: :ok
        else
          render json: { error: result.error || 'Unable to load products' }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error "Products index error: #{e.class.name} - #{e.message}"
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end
  end
end

