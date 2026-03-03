module Api
  module V1
    module Marketplace
      class OrdersController < BaseController
        # POST /api/v1/marketplace/orders/prepare
        def prepare
          result =
            Marketplace::Orders::Prepare.call(
              user: current_user,
              cart_items: prepare_params[:cart_items] || [],
              shipping_address: prepare_params[:shipping_address] || {},
              recipient_info: prepare_params[:recipient_info] || {},
              selected_date: prepare_params[:selected_date],
              shipping_cost: prepare_params[:shipping_cost],
              payment_method: prepare_params[:payment_method],
              purchase_intent_id: prepare_params[:purchase_intent_id]
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
            Marketplace::Orders::Complete.call(
              purchase_id: complete_params[:purchase_id],
              order_ids: complete_params[:order_ids],
              cart_id: complete_params[:cart_id],
              user: current_user
            )

          if result.success?
            render json: {
              purchase: JSON.parse(PurchaseBlueprint.render(result.purchase)),
              orders: JSON.parse(OrderBlueprint.render(result.orders))
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
            shipping_address: {},
            recipient_info: {},
            cart_items: %i[product_id quantity price] + [metadata: {}]
          )
        end

        def complete_params
          params.permit(:purchase_id, :cart_id, order_ids: [])
        end

        def serialize_prepare_result(result)
          {
            purchase_intent:
              JSON.parse(
                PurchaseIntentBlueprint.render(result.purchase_intent)
              ),
            purchase:
              JSON.parse(
                PurchaseBlueprint.render(result.purchase)
              ),
            orders:
              JSON.parse(
                OrderBlueprint.render([result.order])
              ),
            external_reference: result.purchase_intent.external_reference
          }
        end
      end
    end
  end
end

