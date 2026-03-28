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
              order_info: permitted_params[:order] || {},
              shipping_address: permitted_params[:shipping_address] || {},
              recipient_info: permitted_params[:recipient_info] || {},
              expiration_time: permitted_params[:expiration_time]
            )

          if result.error
            render json: { error: result.error }, status: :unprocessable_entity
          else
            render json: {
              payment: JSON.parse(PaymentBlueprint.render(result.payment)),
              checkout_url: result.checkout_url,
              fields: result.fields
            }, status: :ok
          end
        rescue StandardError => e
          Rails.logger.error "Marketplace checkout prepare error: #{e.class.name} - #{e.message}"
          render json: { error: "Internal server error" }, status: :internal_server_error
        end

        # POST /api/v1/marketplace/checkout/webhook
        def webhook
          result =
            ::Marketplace::Checkout::Webhook.call(
              payload: params.to_unsafe_h,
              header_checksum: request.headers["X-Event-Checksum"]
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

        # GET /api/v1/marketplace/checkout/status
        def status
          result =
            ::Marketplace::Checkout::Status.call(
              transaction_id: status_params[:transaction_id],
              external_reference: status_params[:external_reference]
            )

          if result.error.present?
            render json: { error: result.error }, status: :unprocessable_entity
            return
          end

          render json: {
            status: result.status,
            provider_status: result.provider_status,
            transaction_id: result.transaction_id,
            external_reference: result.external_reference,
            amount: result.amount,
            currency: result.currency
          }, status: :ok
        rescue StandardError => e
          Rails.logger.error "Marketplace checkout status error: #{e.class.name} - #{e.message}"
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
            :expiration_time,
            payer: %i[name email phone document],
            order: %i[amount currency provider],
            shipping_address: {},
            recipient_info: {}
          )
        end

        def status_params
          params.permit(:transaction_id, :external_reference)
        end
      end
    end
  end
end

