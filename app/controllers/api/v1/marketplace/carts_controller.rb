module Api
  module V1
    module Marketplace
      class CartsController < BaseController
        # GET /api/v1/marketplace/cart
        def show
          result = ::Marketplace::Carts::FetchOpen.call(user: current_user)

          if result.success?
            cart_json = if result.cart
                          JSON.parse(
                            CartBlueprint.render(
                              result.cart,
                              view: :default,
                              level_id: current_user.level_id
                            )
                          )
                        else
                          nil
                        end

          render json: { cart: cart_json }, status: :ok
          else
            render json: { error: result.error || 'Unable to load cart' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart show error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end
      end
    end
  end
end

