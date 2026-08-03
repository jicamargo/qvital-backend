module Admin
  module Orders
    class ReconcileWompiPayment
      Result = Struct.new(
        :order,
        :payment,
        :error,
        keyword_init: true
      )

      def self.call(order_id:)
        new(order_id:).call
      end

      def initialize(order_id:)
        @order_id = order_id
      end

      def call
        order = Order.includes(purchase: [:purchase_intent, :payments]).find_by(id: @order_id)
        return Result.new(error: "Order not found") unless order

        purchase = order.purchase
        external_reference = purchase&.purchase_intent&.external_reference
        return Result.new(error: "Purchase has no external_reference") if external_reference.blank?

        transactions = ::Wompi::Client.fetch_transactions_by_reference(reference: external_reference)
        approved_transaction = transactions.find { |tx| tx["status"].to_s.upcase == "APPROVED" }
        return Result.new(error: "No approved transaction found in Wompi for this reference") unless approved_transaction

        reconciled =
          ::Marketplace::Checkout::ReconcileTransaction.call(
            external_reference:,
            provider_payment_id: approved_transaction["id"],
            status: approved_transaction["status"],
            amount_in_cents: approved_transaction["amount_in_cents"],
            currency: approved_transaction["currency"] || "COP"
          )

        return Result.new(error: reconciled.error) unless reconciled.success?

        Result.new(order: order.reload, payment: reconciled.payment)
      rescue StandardError => e
        Rails.logger.error "Error reconciling Wompi payment for order #{@order_id}: #{e.class.name} - #{e.message}"
        Result.new(error: "Unexpected error reconciling payment")
      end
    end
  end
end
