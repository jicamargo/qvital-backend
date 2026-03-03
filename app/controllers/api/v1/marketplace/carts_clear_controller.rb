module Api
  module V1
    module Marketplace
      class CartsClearController < BaseController
        # POST /api/v1/marketplace/cart/clear
        def create
          result = ::Marketplace::Carts::Clear.call(user: current_user)

          if result.success?
            cart_json = JSON.parse(
              CartBlueprint.render(
                result.cart,
                view: :default,
                level_id: current_user.level_id
              )
            )

            render json: { cart: cart_json }, status: :ok
          else
            render json: { error: result.error || 'Unable to clear cart' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart clear error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end
      end
    end
  end
end

