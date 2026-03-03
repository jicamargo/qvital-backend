module Marketplace
  module Checkout
    class Webhook
      attr_reader :payment, :error

      def self.call(external_reference:, provider:, status:, provider_payment_id:, amount: nil, raw_payload: {})
        new(
          external_reference:,
          provider:,
          status:,
          provider_payment_id:,
          amount:,
          raw_payload:
        ).call
      end

      def initialize(external_reference:, provider:, status:, provider_payment_id:, amount:, raw_payload:)
        @external_reference = external_reference
        @provider = provider
        @status = status
        @provider_payment_id = provider_payment_id
        @amount = amount
        @raw_payload = raw_payload || {}
        @payment = nil
        @error = nil
      end

      def call
        ActiveRecord::Base.transaction do
          @payment =
            Payment.where(
              external_reference: @external_reference,
              provider: @provider
            ).first_or_initialize

          @payment.provider_payment_id = @provider_payment_id
          @payment.amount = @amount if @amount
          @payment.status = map_status(@status)
          @payment.raw_payload = (@payment.raw_payload || {}).merge(@raw_payload)

          @payment.save!

          if @payment.approved?
            complete_order_for_payment!(@payment)
          end
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error processing payment webhook: #{e.message}"
        failure("Unexpected error processing payment webhook")
      end

      def success?
        @error.nil?
      end

      private

      def complete_order_for_payment!(payment)
        purchase = payment.purchase
        return unless purchase

        order = purchase.order
        return unless order

        Marketplace::Orders::Complete.call(
          purchase_id: purchase.id,
          order_ids: [order.id],
          cart_id: nil,
          user: nil
        )
      end

      def map_status(provider_status)
        case provider_status.to_s
        when "approved", "succeeded"
          :approved
        when "rejected", "failed"
          :rejected
        else
          :pending
        end
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end

