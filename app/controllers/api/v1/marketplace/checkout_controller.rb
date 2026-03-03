module Api
  module V1
    module Marketplace
      class CheckoutController < BaseController
        skip_before_action :authenticate_user!, only: [:webhook]

        # POST /api/v1/marketplace/checkout/prepare
        def prepare
          result =
            Marketplace::Checkout::Prepare.call(
              external_reference: prepare_params[:external_reference],
              payer: prepare_params[:payer] || {},
              order_info: prepare_params[:order] || {}
            )

          if result.error
            render json: { error: result.error }, status: :unprocessable_entity
          else
            render json: {
              payment: JSON.parse(PaymentBlueprint.render(result.payment)),
              preference_id: result.preference_id,
              init_point: result.init_point
            }, status: :ok
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace checkout prepare error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # POST /api/v1/marketplace/checkout/webhook
        def webhook
          result =
            Marketplace::Checkout::Webhook.call(
              external_reference: webhook_params[:external_reference],
              provider: webhook_params[:provider],
              status: webhook_params[:status],
              provider_payment_id: webhook_params[:provider_payment_id],
              amount: webhook_params[:amount],
              raw_payload: params.to_unsafe_h
            )

          if result.success?
            head :ok
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace checkout webhook error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        private

        def prepare_params
          params.permit(
            :external_reference,
            payer: %i[name email phone document],
            order: %i[amount currency provider]
          )
        end

        def webhook_params
          params.permit(
            :external_reference,
            :provider,
            :status,
            :provider_payment_id,
            :amount
          )
        end
      end
    end
  end
end

