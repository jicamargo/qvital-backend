module Marketplace
  module Checkout
    class Prepare
      Result = Struct.new(
        :payment,
        :preference_id,
        :init_point,
        :error,
        keyword_init: true
      )

      def self.call(external_reference:, payer:, order_info:)
        new(external_reference:, payer:, order_info:).call
      end

      def initialize(external_reference:, payer:, order_info:)
        @external_reference = external_reference
        @payer = payer || {}
        @order_info = order_info || {}
      end

      def call
        purchase_intent =
          PurchaseIntent.find_by!(external_reference: @external_reference)

        purchase = purchase_intent.purchase
        return Result.new(error: "Purchase not found for intent") unless purchase

        amount = purchase.total_amount
        currency = @order_info[:currency] || "MXN"
        provider = @order_info[:provider] || "mock_provider"

        preference_id = SecureRandom.uuid
        init_point = "https://payments.qvital.local/checkout/#{preference_id}"

        payment =
          Payment.where(
            purchase:,
            external_reference: @external_reference,
            provider:
          ).first_or_initialize

        payment.amount = amount
        payment.currency = currency
        payment.status ||= :pending
        payment.provider_preference_id = preference_id
        payment.raw_payload = {
          payer: @payer,
          order: @order_info
        }

        payment.save!

        Result.new(
          payment:,
          preference_id:,
          init_point:
        )
      rescue ActiveRecord::RecordNotFound
        Result.new(error: "Purchase intent not found for external_reference")
      rescue StandardError => e
        Rails.logger.error "Error preparing checkout with provider: #{e.message}"
        Result.new(error: "Unexpected error preparing checkout with provider")
      end
    end
  end
end

