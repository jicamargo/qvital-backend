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
        return failure("Missing transaction reference") if external_reference.blank?
        return failure("Missing transaction id") if provider_payment_id.blank?

        result =
          ReconcileTransaction.call(
            external_reference:,
            provider_payment_id:,
            status: transaction["status"],
            amount_in_cents: transaction["amount_in_cents"],
            currency: transaction["currency"] || "COP",
            raw_event: { "wompi_event" => sanitized_wompi_event(transaction) }
          )

        @payment = result.payment
        return failure(result.error) unless result.success?

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

      def failure(message)
        @error = message
        self
      end
    end
  end
end
