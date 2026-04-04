module Marketplace
  module Checkout
    class Status
      Result = Struct.new(
        :status,
        :provider_status,
        :transaction_id,
        :external_reference,
        :amount,
        :currency,
        :payment,
        :error,
        keyword_init: true
      )

      def self.call(transaction_id: nil, external_reference: nil)
        new(transaction_id:, external_reference:).call
      end

      def initialize(transaction_id:, external_reference:)
        @transaction_id = transaction_id
        @external_reference = external_reference
      end

      def call
        return Result.new(error: "transaction_id or external_reference is required") if @transaction_id.blank? && @external_reference.blank?

        payment = find_local_payment
        if payment
          return Result.new(
            status: normalize_status(payment.status),
            provider_status: payment.status,
            transaction_id: payment.provider_payment_id,
            external_reference: payment.external_reference,
            amount: payment.amount,
            currency: payment.currency,
            payment:
          )
        end

        return Result.new(error: "Payment not found") if @transaction_id.blank?

        tx = ::Wompi::Client.fetch_transaction(transaction_id: @transaction_id)
        return Result.new(error: "Payment not found") unless tx

        Rails.logger.info "Wompi transaction: #{tx.inspect}"
        
        Result.new(
          status: normalize_status(tx["status"]),
          provider_status: tx["status"],
          transaction_id: tx["id"],
          external_reference: tx["reference"],
          amount: BigDecimal(tx["amount_in_cents"].to_s) / 100,
          currency: tx["currency"]
        )
      rescue StandardError => e
        Result.new(error: "Unexpected error fetching payment status: #{e.message}")
      end

      private

      def find_local_payment
        if @transaction_id.present?
          payment =
            Payment.where(provider: "wompi", provider_payment_id: @transaction_id).order(updated_at: :desc).first
          return payment if payment
        end

        return nil if @external_reference.blank?

        Payment.where(provider: "wompi", external_reference: @external_reference).order(updated_at: :desc).first
      end

      def normalize_status(raw_status)
        case raw_status.to_s.upcase
        when "APPROVED", "APPROVED_ONLY_POINTS", "APPROVED_HALF_POINTS"
          "approved"
        when "REJECTED"
          "declined"
        when "DECLINED"
          "declined"
        when "VOIDED"
          "voided"
        when "ERROR"
          "error"
        else
          "pending"
        end
      end
    end
  end
end
