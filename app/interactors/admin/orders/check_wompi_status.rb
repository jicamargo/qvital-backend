module Admin
  module Orders
    class CheckWompiStatus
      Result = Struct.new(
        :order,
        :external_reference,
        :local_status,
        :wompi_transaction,
        :mismatch,
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
        wompi_transaction = pick_best_transaction(transactions)

        local_approved = purchase.payments.approved.exists?
        wompi_approved = wompi_transaction.present? && wompi_transaction["status"].to_s.upcase == "APPROVED"

        Result.new(
          order:,
          external_reference:,
          local_status: purchase.status,
          wompi_transaction:,
          mismatch: wompi_approved && !local_approved
        )
      rescue StandardError => e
        Rails.logger.error "Error checking Wompi status for order #{@order_id}: #{e.class.name} - #{e.message}"
        Result.new(error: "Unexpected error checking Wompi status")
      end

      private

      # Prioriza la transacción aprobada (puede haber varias por reintentos);
      # si ninguna está aprobada, muestra la más reciente.
      def pick_best_transaction(transactions)
        return nil if transactions.blank?

        transactions.find { |tx| tx["status"].to_s.upcase == "APPROVED" } ||
          transactions.max_by { |tx| tx["created_at"].to_s }
      end
    end
  end
end
