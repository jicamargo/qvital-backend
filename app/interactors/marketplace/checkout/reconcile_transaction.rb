module Marketplace
  module Checkout
    # Aplica a un Payment local el mismo efecto que produciría el webhook de Wompi
    # (upsert de Payment + completar la orden/carrito si quedó aprobado). Se usa tanto
    # desde el webhook como desde el polling de status, para no depender solo del webhook.
    class ReconcileTransaction
      attr_reader :payment, :error, :mismatch

      def self.call(external_reference:, provider_payment_id:, status:, amount_in_cents: nil, currency: "COP", raw_event: nil)
        new(
          external_reference:,
          provider_payment_id:,
          status:,
          amount_in_cents:,
          currency:,
          raw_event:
        ).call
      end

      def initialize(external_reference:, provider_payment_id:, status:, amount_in_cents:, currency:, raw_event:)
        @external_reference = external_reference
        @provider_payment_id = provider_payment_id
        @status = status
        @amount_in_cents = amount_in_cents
        @currency = currency
        @raw_event = raw_event
        @payment = nil
        @error = nil
      end

      def call
        already_alerted = false
        return failure("Missing transaction reference") if @external_reference.blank?
        return failure("Missing transaction id") if @provider_payment_id.blank?

        ActiveRecord::Base.transaction do
          purchase_intent = PurchaseIntent.find_by(external_reference: @external_reference)
          purchase = purchase_intent&.purchase

          @payment =
            Payment.where(provider: "wompi", provider_payment_id: @provider_payment_id).first

          # Una referencia puede tener varias transacciones (p. ej. una rechazada
          # y luego otra aprobada): solo se reutiliza la fila creada al preparar
          # el checkout, que aún no tiene transacción; si no, cada transacción
          # tiene su propia fila.
          @payment ||=
            Payment.where(external_reference: @external_reference, provider: "wompi", provider_payment_id: nil)
              .order(updated_at: :desc)
              .first_or_initialize
          @payment.lock! if @payment.persisted?

          if @payment.new_record?
            return failure("Purchase not found for transaction reference") unless purchase

            @payment.purchase = purchase
            @payment.external_reference = @external_reference
            @payment.provider = "wompi"
          end

          new_status = map_status(@status)
          @mismatch = charge_mismatch(@payment.purchase) if new_status == :approved
          already_alerted = @payment.raw_payload.to_h.key?("charge_mismatch")

          @payment.provider_payment_id = @provider_payment_id
          unless @payment.approved?
            @payment.amount = BigDecimal(@amount_in_cents.to_s) / 100 if @amount_in_cents.present?
            @payment.currency = @currency
          end
          # Un pago aprobado es definitivo: un evento tardío (PENDING/DECLINED)
          # no lo puede devolver atrás. Si lo cobrado no coincide con la compra,
          # no se aprueba y se avisa al admin para revisarlo a mano.
          @payment.status = new_status unless @payment.approved? || @mismatch
          @payment.raw_payload = (@payment.raw_payload || {}).merge(@raw_event) if @raw_event.present?
          @payment.raw_payload = @payment.raw_payload.merge("charge_mismatch" => @mismatch) if @mismatch

          @payment.save!

          if @payment.approved? && @payment.purchase&.order
            complete_order_for_payment!(@payment)
          end
        end

        if @mismatch
          alert_admin_of_mismatch unless already_alerted
          return failure("Charged amount does not match the purchase")
        end

        self
      rescue StandardError => e
        Rails.logger.error "Error reconciling transaction: #{e.class.name} - #{e.message}"
        failure("Unexpected error reconciling transaction")
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
          user: nil
        )
      end

      def charge_mismatch(purchase)
        return nil unless purchase

        expected_cents = (purchase.total_amount * 100).to_i
        charged_cents = @amount_in_cents.to_i
        return nil if charged_cents == expected_cents && @currency.to_s.upcase == "COP"

        "Wompi cobró #{charged_cents} centavos #{@currency}; la compra #{purchase.purchase_number} " \
          "vale #{expected_cents} centavos COP."
      end

      def alert_admin_of_mismatch
        Rails.logger.error "Wompi charge mismatch for payment #{@payment.id}: #{@mismatch}"
        return unless ENV["ADMIN_NOTIFICATION_EMAIL"].present?

        OrderMailer.payment_alert(@payment, @mismatch).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue payment alert for payment #{@payment.id}: #{e.message}"
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
