module Api
  module V1
    module Marketplace
      class CheckoutController < BaseController
        skip_before_action :authenticate_user!, only: [:webhook]

        # POST /api/v1/marketplace/checkout/prepare
        def prepare
          permitted_params = prepare_params

          result =
            ::Marketplace::Checkout::Prepare.call(
              external_reference: permitted_params[:external_reference],
              payer: permitted_params[:payer] || {},
              order_info: permitted_params[:order] || {}
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
          permitted_params = webhook_params

          result =
            ::Marketplace::Checkout::Webhook.call(
              external_reference: permitted_params[:external_reference],
              provider: permitted_params[:provider],
              status: permitted_params[:status],
              provider_payment_id: permitted_params[:provider_payment_id],
              amount: permitted_params[:amount],
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
          source_params =
            if params[:checkout].is_a?(ActionController::Parameters)
              params[:checkout]
            else
              params
            end

          source_params.permit(
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

