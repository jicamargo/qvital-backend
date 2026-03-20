module Api
  module V1
    module Marketplace
      class OrdersController < BaseController
        # POST /api/v1/marketplace/orders/prepare
        def prepare
          permitted_params = prepare_params

          result =
            ::Marketplace::Orders::Prepare.call(
              user: current_user,
              cart_items: permitted_params[:cart_items] || [],
              shipping_address: permitted_params[:shipping_address] || {},
              recipient_info: permitted_params[:recipient_info] || {},
              selected_date: permitted_params[:selected_date],
              shipping_cost: permitted_params[:shipping_cost],
              payment_method: permitted_params[:payment_method],
              purchase_intent_id: permitted_params[:purchase_intent_id],
              update_user_profile: permitted_params[:update_user_profile]
            )

          if result.error
            render json: { error: result.error }, status: :unprocessable_entity
          else
            render json: serialize_prepare_result(result), status: :ok
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace orders prepare error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # POST /api/v1/marketplace/orders/complete
        def complete
          result =
            ::Marketplace::Orders::Complete.call(
              purchase_id: complete_params[:purchase_id],
              order_ids: complete_params[:order_ids],
              cart_id: complete_params[:cart_id],
              user: current_user
            )

          if result.success?
            preloaded_purchase =
              Purchase
                .includes(purchase_items: { product: :category })
                .find(result.purchase.id)
            preloaded_orders =
              Order
                .includes(order_items: { product: :category })
                .where(id: result.orders.map(&:id))

            render json: {
              purchase: JSON.parse(PurchaseBlueprint.render(preloaded_purchase)),
              orders: JSON.parse(OrderBlueprint.render(preloaded_orders))
            }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace orders complete error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        def prepare_params
          params.permit(
            :selected_date,
            :shipping_cost,
            :payment_method,
            :purchase_intent_id,
            :update_user_profile,
            order: {},
            shipping_address: {},
            recipient_info: {},
            cart_items: %i[product_id quantity price] + [metadata: {}]
          )
        end

        def complete_params
          params.permit(:purchase_id, :cart_id, order_ids: [], order: {})
        end

        def serialize_prepare_result(result)
          preloaded_purchase =
            Purchase
              .includes(purchase_items: { product: :category })
              .find(result.purchase.id)
          preloaded_order =
            Order
              .includes(order_items: { product: :category })
              .find(result.order.id)

          {
            purchase_intent:
              JSON.parse(
                PurchaseIntentBlueprint.render(result.purchase_intent)
              ),
            purchase:
              JSON.parse(
                PurchaseBlueprint.render(preloaded_purchase)
              ),
            orders:
              JSON.parse(
                OrderBlueprint.render([preloaded_order])
              ),
            external_reference: result.purchase_intent.external_reference
          }
        end
      end
    end
  end
end

