module Api
  module V1
    module Marketplace
      class CartsRepeatController < BaseController
        # POST /api/v1/marketplace/cart/repeat_last_order
        def create
          result = ::Marketplace::Carts::RepeatLastOrder.call(user: current_user)

          if result.success?
            cart_json = JSON.parse(
              CartBlueprint.render(
                result.cart,
                view: :default,
                level_id: current_user.level_id
              )
            )

            render json: { cart: cart_json, skipped: result.skipped }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart repeat error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end
      end
    end
  end
end
