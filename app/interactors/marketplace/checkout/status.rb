module Marketplace
  module Checkout
    # Estado de un pago para la pantalla de resultado del checkout. Solo
    # responde por pagos del propio usuario.
    class Status
      Result = Struct.new(
        :status,
        :provider_status,
        :transaction_id,
        :external_reference,
        :amount,
        :currency,
        :payment,
        :purchase_number,
        :error,
        keyword_init: true
      )

      def self.call(user:, transaction_id: nil, external_reference: nil)
        new(user:, transaction_id:, external_reference:).call
      end

      def initialize(user:, transaction_id:, external_reference:)
        @user = user
        @transaction_id = transaction_id
        @external_reference = external_reference
      end

      def call
        return Result.new(error: "transaction_id or external_reference is required") if @transaction_id.blank? && @external_reference.blank?

        payment = find_local_payment
        # Mientras siga pendiente se vuelve a preguntar a Wompi: si el webhook
        # tarda o nunca llega, el pago no se queda "en proceso" para siempre.
        return local_result(payment) if payment && !(payment.pending? && @transaction_id.present?)

        return Result.new(error: "Payment not found") if @transaction_id.blank?

        tx = ::Wompi::Client.fetch_transaction(transaction_id: @transaction_id)
        return Result.new(error: "Payment not found") unless tx && belongs_to_user?(tx)

        normalized_status = normalize_status(tx["status"])
        reconciliation = reconcile_if_final(tx, normalized_status)
        # Wompi lo aprobó, pero el cobro no coincide con la compra: queda en
        # revisión del admin, así que la clienta lo ve "en proceso".
        normalized_status = "pending" if reconciliation&.mismatch
        reconciled_payment = reconciliation&.payment || payment

        Result.new(
          status: normalized_status,
          provider_status: tx["status"],
          transaction_id: tx["id"],
          external_reference: tx["reference"],
          amount: BigDecimal(tx["amount_in_cents"].to_s) / 100,
          currency: tx["currency"],
          payment: reconciled_payment,
          purchase_number: reconciled_payment&.purchase&.purchase_number
        )
      rescue StandardError => e
        Rails.logger.error "Error fetching payment status: #{e.class.name} - #{e.message}"
        Result.new(error: "Unexpected error fetching payment status")
      end

      private

      def local_result(payment)
        Result.new(
          status: normalize_status(payment.status),
          provider_status: payment.status,
          transaction_id: payment.provider_payment_id,
          external_reference: payment.external_reference,
          amount: payment.amount,
          currency: payment.currency,
          payment:,
          purchase_number: payment.purchase&.purchase_number
        )
      end

      def belongs_to_user?(tx)
        PurchaseIntent.exists?(external_reference: tx["reference"], user_id: @user.id)
      end

      # El estado final normalmente lo procesa el webhook de Wompi (upsert de Payment
      # + completar orden/carrito). Si el webhook aún no llegó (o nunca llega), este polling
      # de status hace lo mismo al detectar un estado final, para no depender solo del webhook.
      def reconcile_if_final(tx, normalized_status)
        return nil if normalized_status == "pending"

        result =
          ReconcileTransaction.call(
            external_reference: tx["reference"],
            provider_payment_id: tx["id"],
            status: tx["status"],
            amount_in_cents: tx["amount_in_cents"],
            currency: tx["currency"] || "COP"
          )

        Rails.logger.warn "Failed to reconcile transaction #{tx['id']}: #{result.error}" unless result.success?
        result
      rescue StandardError => e
        Rails.logger.error "Error reconciling transaction from status poll: #{e.class.name} - #{e.message}"
        nil
      end

      def find_local_payment
        scope = Payment.joins(:purchase).where(provider: "wompi", purchases: { user_id: @user.id })

        if @transaction_id.present?
          payment = scope.where(provider_payment_id: @transaction_id).order(updated_at: :desc).first
          return payment if payment
        end

        return nil if @external_reference.blank?

        scope.where(external_reference: @external_reference).order(updated_at: :desc).first
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
