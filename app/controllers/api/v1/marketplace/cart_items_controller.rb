module Api
  module V1
    module Marketplace
      class CartItemsController < BaseController
        # POST /api/v1/marketplace/cart/items
        def create
          result =
            ::Marketplace::Carts::AddItem.call(
              user: current_user,
              product_id: cart_item_params[:product_id],
              quantity: cart_item_params[:quantity],
              price_snapshot: cart_item_params[:price_snapshot]
            )

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
            render json: { error: result.error || 'Unable to add item to cart' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart items create error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # PATCH /api/v1/marketplace/cart/items/:id
        def update
          result =
            ::Marketplace::Carts::UpdateItem.call(
              user: current_user,
              cart_item_id: params[:id],
              quantity: cart_item_params[:quantity]
            )

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
            render json: { error: result.error || 'Unable to update cart item' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart items update error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        # DELETE /api/v1/marketplace/cart/items/:id
        def destroy
          result =
            ::Marketplace::Carts::RemoveItem.call(
              user: current_user,
              cart_item_id: params[:id]
            )

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
            render json: { error: result.error || 'Unable to remove cart item' }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace cart items destroy error: #{e.class.name} - #{e.message}"
          render json: { error: 'Internal server error' }, status: :internal_server_error
        end

        private

        def cart_item_params
          params.require(:cart_item).permit(:product_id, :quantity, :price_snapshot)
        end
      end
    end
  end
end

