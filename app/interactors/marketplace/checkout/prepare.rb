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
        ActiveRecord::Base.transaction do
          purchase_intent =
            PurchaseIntent.find_by!(external_reference: @external_reference)

          purchase = purchase_intent.purchase
          return Result.new(error: "Purchase not found for intent") unless purchase

          amount = purchase.total_amount
          currency = @order_info[:currency] || "COP"
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
          if auto_approve_mock_payment?(provider)
            payment.status = :approved
            payment.provider_payment_id ||= "mock-#{SecureRandom.uuid}"
          elsif payment.status.blank?
            payment.status = :pending
          end
          payment.provider_preference_id = preference_id
          payment.raw_payload = {
            payer: @payer,
            order: @order_info
          }
          if auto_approve_mock_payment?(provider)
            payment.raw_payload["mock_auto_approved"] = true
            payment.raw_payload["mock_auto_approved_at"] = Time.current.iso8601
          end

          payment.save!

          Result.new(
            payment:,
            preference_id:,
            init_point:
          )
        end
      rescue ActiveRecord::RecordNotFound
        Result.new(error: "Purchase intent not found for external_reference")
      rescue StandardError => e
        Rails.logger.error "Error preparing checkout with provider: #{e.message}"
        Result.new(error: "Unexpected error preparing checkout with provider")
      end

      private

      def auto_approve_mock_payment?(provider)
        return false unless provider.to_s == "mock_provider"

        default_value = Rails.env.development? || Rails.env.staging?
        env_value = ENV.fetch("MARKETPLACE_MOCK_AUTO_APPROVE", default_value.to_s)
        ActiveModel::Type::Boolean.new.cast(env_value)
      end
    end
  end
end

