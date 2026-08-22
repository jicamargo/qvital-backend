module Marketplace
  module Checkout
    # Aplica a un Payment local el mismo efecto que produciría el webhook de Wompi
    # (upsert de Payment + completar la orden/carrito si quedó aprobado). Se usa tanto
    # desde el webhook como desde el polling de status, para no depender solo del webhook.
    class ReconcileTransaction
      attr_reader :payment, :error

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
        return failure("Missing transaction reference") if @external_reference.blank?
        return failure("Missing transaction id") if @provider_payment_id.blank?

        ActiveRecord::Base.transaction do
          purchase_intent = PurchaseIntent.find_by(external_reference: @external_reference)
          purchase = purchase_intent&.purchase

          @payment =
            Payment.where(provider: "wompi", provider_payment_id: @provider_payment_id).first

          @payment ||=
            Payment.where(external_reference: @external_reference, provider: "wompi")
              .order(updated_at: :desc)
              .first_or_initialize

          if @payment.new_record?
            return failure("Purchase not found for transaction reference") unless purchase

            @payment.purchase = purchase
            @payment.external_reference = @external_reference
            @payment.provider = "wompi"
          end

          @payment.provider_payment_id = @provider_payment_id
          @payment.amount = BigDecimal(@amount_in_cents.to_s) / 100 if @amount_in_cents.present?
          @payment.currency = @currency
          @payment.status = map_status(@status)
          @payment.raw_payload = (@payment.raw_payload || {}).merge(@raw_event) if @raw_event.present?

          @payment.save!

          if @payment.approved? && @payment.purchase&.order
            complete_order_for_payment!(@payment, cart_id: find_open_cart_id_for_purchase(@payment.purchase))
          end
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
