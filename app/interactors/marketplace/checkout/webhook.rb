module Marketplace
  module Checkout
    class Webhook
      attr_reader :payment, :error

      def self.call(payload:, header_checksum: nil)
        new(
          payload:,
          header_checksum:
        ).call
      end

      def initialize(payload:, header_checksum:)
        @payload = payload || {}
        @header_checksum = header_checksum
        @payment = nil
        @error = nil
      end

      def call
        return self unless transaction_updated_event?
        return failure("Invalid webhook environment") unless valid_environment?
        return failure("Invalid webhook signature") unless valid_signature?

        transaction = @payload.dig("data", "transaction") || {}
        external_reference = transaction["reference"]
        provider_payment_id = transaction["id"]
        status = transaction["status"]
        amount = transaction["amount_in_cents"]
        currency = transaction["currency"] || "COP"
        return failure("Missing transaction reference") if external_reference.blank?
        return failure("Missing transaction id") if provider_payment_id.blank?

        ActiveRecord::Base.transaction do
          purchase_intent = PurchaseIntent.find_by(external_reference:)
          purchase = purchase_intent&.purchase

          @payment =
            Payment.where(
              provider: "wompi",
              provider_payment_id:
            ).first

          @payment ||=
            Payment.where(
              external_reference:,
              provider: "wompi"
            ).order(updated_at: :desc).first_or_initialize

          if @payment.new_record?
            return failure("Purchase not found for transaction reference") unless purchase

            @payment.purchase = purchase
            @payment.external_reference = external_reference
            @payment.provider = "wompi"
          end

          @payment.provider_payment_id = provider_payment_id
          @payment.amount = BigDecimal(amount.to_s) / 100 if amount.present?
          @payment.currency = currency
          @payment.status = map_status(status)
          @payment.raw_payload =
            (@payment.raw_payload || {}).merge(
              "wompi_event" => sanitized_wompi_event(transaction)
            )

          @payment.save!

          if @payment.approved? && @payment.purchase&.order
            complete_order_for_payment!(
              @payment,
              cart_id: find_open_cart_id_for_purchase(@payment.purchase)
            )
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

      def transaction_updated_event?
        @payload["event"].to_s == "transaction.updated"
      end

      def valid_environment?
        @payload["environment"].to_s == ::Wompi::Config.expected_webhook_environment
      end

      def valid_signature?
        ::Wompi::Signature.valid_webhook_checksum?(payload: @payload, header_checksum: @header_checksum)
      end

      def complete_order_for_payment!(payment, cart_id:)
        purchase = payment.purchase
        return unless purchase

        order = purchase.order
        return unless order

        Marketplace::Orders::Complete.call(
          purchase_id: purchase.id,
          order_ids: [order.id],
          cart_id:,
          user: nil
        )
      end

      def find_open_cart_id_for_purchase(purchase)
        return nil unless purchase&.user_id

        Cart
          .where(user_id: purchase.user_id, status: :open)
          .order(created_at: :desc)
          .pick(:id)
      end

      def sanitized_wompi_event(transaction)
        {
          "event" => @payload["event"],
          "environment" => @payload["environment"],
          "timestamp" => @payload["timestamp"],
          "sent_at" => @payload["sent_at"],
          "signature" => {
            "checksum" => @payload.dig("signature", "checksum"),
            "properties" => @payload.dig("signature", "properties")
          },
          "transaction" => {
            "id" => transaction["id"],
            "reference" => transaction["reference"],
            "status" => transaction["status"],
            "status_message" => transaction["status_message"],
            "amount_in_cents" => transaction["amount_in_cents"],
            "currency" => transaction["currency"],
            "payment_method_type" => transaction["payment_method_type"],
            "created_at" => transaction["created_at"],
            "finalized_at" => transaction["finalized_at"],
            "redirect_url" => transaction["redirect_url"]
          }
        }
      end

      def map_status(provider_status)
        case provider_status.to_s
        when "APPROVED", "approved", "succeeded"
          :approved
        when "DECLINED", "VOIDED", "ERROR", "rejected", "failed"
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

