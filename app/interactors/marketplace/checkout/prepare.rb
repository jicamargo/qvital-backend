module Marketplace
  module Checkout
    class Prepare
      Result = Struct.new(
        :payment,
        :checkout_url,
        :fields,
        :error,
        keyword_init: true
      )

      def self.call(external_reference:, payer:, order_info:, shipping_address: {}, recipient_info: {}, expiration_time: nil)
        new(
          external_reference:,
          payer:,
          order_info:,
          shipping_address:,
          recipient_info:,
          expiration_time:
        ).call
      end

      def initialize(external_reference:, payer:, order_info:, shipping_address:, recipient_info:, expiration_time:)
        @external_reference = external_reference
        @payer = payer || {}
        @order_info = order_info || {}
        @shipping_address = shipping_address || {}
        @recipient_info = recipient_info || {}
        @expiration_time = expiration_time
      end

      def call
        ActiveRecord::Base.transaction do
          purchase_intent =
            PurchaseIntent.find_by!(external_reference: @external_reference)

          purchase = purchase_intent.purchase
          return Result.new(error: "Purchase not found for intent") unless purchase

          # Forzar provider interno para evitar duplicados si FE envía un valor incorrecto.
          provider = "wompi"
          wompi_result =
            ::Wompi::CheckoutPrepare.call(
              purchase:,
              payer: @payer,
              shipping_address: @shipping_address,
              recipient_info: @recipient_info,
              expiration_time: @expiration_time
            )
          return Result.new(error: wompi_result.error) if wompi_result.error.present?

          payment =
            Payment.where(
              purchase:,
              external_reference: @external_reference,
              provider:
            ).first_or_initialize

          payment.amount = purchase.total_amount
          payment.currency = "COP"
          payment.status = :pending
          payment.provider_preference_id = wompi_result.reference
          payment.raw_payload = {
            payer: @payer,
            order: @order_info.merge(provider: provider),
            wompi_checkout: {
              checkout_url: wompi_result.checkout_url,
              fields: wompi_result.fields
            }
          }

          payment.save!

          Result.new(
            payment:,
            checkout_url: wompi_result.checkout_url,
            fields: wompi_result.fields
          )
        end
      rescue ActiveRecord::RecordNotFound
        Result.new(error: "Purchase intent not found for external_reference")
      rescue StandardError => e
        Rails.logger.error "Error preparing checkout with provider: #{e.message}"
        Result.new(error: "Unexpected error preparing checkout with provider")
      end
    end
  end
end

