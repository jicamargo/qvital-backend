module Api
  module V1
    module Admin
      class OrdersController < BaseController
        before_action :authorize_admin!

        def index
          result =
            ::Admin::Orders::List.call(
              status: index_params[:status],
              page: index_params[:page] || 1,
              per_page: index_params[:per_page] || 20,
              search: index_params[:search],
              from: index_params[:from],
              to: index_params[:to]
            )

          if result.success?
            render json: {
              orders: result.orders.map { |order| serialize_admin_order_list(order) },
              pagination: {
                page: result.page,
                per_page: result.per_page,
                total: result.total
              }
            }, status: :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Admin orders index error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        def show
          result = ::Admin::Orders::Show.call(id: params[:id])

          if result.success?
            render json: serialize_admin_order_show(result.order), status: :ok
          else
            render json: { error: result.error }, status: :not_found
          end
        rescue StandardError => e
          Rails.logger.error "Admin orders show error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        def update
          result =
            ::Admin::Orders::Update.call(
              id: params[:id],
              params: update_params
            )

          if result.success?
            refreshed = ::Admin::Orders::Show.call(id: result.order.id)
            render json: serialize_admin_order_show(refreshed.order), status: :ok
          elsif result.error == "Order not found"
            render json: { error: result.error }, status: :not_found
          else
            render json: { error: result.error, details: result.errors }, status: :unprocessable_entity
          end
        rescue ActionController::ParameterMissing => e
          render json: { error: e.message }, status: :bad_request
        rescue StandardError => e
          Rails.logger.error "Admin orders update error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        def authorize_admin!
          unless current_user&.admin?
            render json: { error: "Forbidden" }, status: :forbidden and return
          end
        end

        def index_params
          params.permit(:status, :page, :per_page, :search, :from, :to)
        end

        def update_params
          raw = params.require(:order)
          # Quitar tracking_info antes de permit para no loguear "unpermitted" ni romper .to_h
          hash = raw.except(:tracking_info).permit(:status, :shipping_date_estimated, :shipping_date_real).to_h
          if raw.key?(:tracking_info)
            hash["tracking_info"] = tracking_info_from_param(raw[:tracking_info])
          end

          hash
        end

        def tracking_info_from_param(value)
          case value
          when ActionController::Parameters
            value.to_unsafe_h
          when Hash
            value
          else
            {}
          end
        end

        def serialize_admin_order_list(order)
          latest_payment = order.purchase.payments.max_by(&:updated_at)
          order_payload = JSON.parse(OrderBlueprint.render(order))
          customer = order.purchase.user

          order_payload.merge(
            "customer" =>
              if customer
                {
                  "id" => customer.id,
                  "email" => customer.email,
                  "name" => customer.name
                }
              end,
            "purchase" => {
              "id" => order.purchase.id,
              "purchase_number" => order.purchase.purchase_number,
              "status" => order.purchase.status,
              "total_amount" => order.purchase.total_amount,
              "external_reference" => order.purchase.purchase_intent&.external_reference
            },
            "latest_payment" => {
              "provider" => latest_payment&.provider,
              "status" => latest_payment&.status,
              "provider_payment_id" => latest_payment&.provider_payment_id,
              "amount" => latest_payment&.amount,
              "currency" => latest_payment&.currency,
              "updated_at" => latest_payment&.updated_at
            }
          )
        end

        def serialize_admin_order_show(order)
          purchase = order.purchase
          user = purchase.user

          {
            order: JSON.parse(OrderBlueprint.render(order)),
            customer: user ? JSON.parse(UserBlueprint.render(user)) : nil,
            purchase: JSON.parse(PurchaseBlueprint.render(purchase)),
            purchase_intent: JSON.parse(PurchaseIntentBlueprint.render(purchase.purchase_intent)),
            payments: JSON.parse(PaymentBlueprint.render(purchase.payments.order(:id)))
          }
        end
      end
    end
  end
end
