module Marketplace
  module Orders
    class Complete
      attr_reader :purchase, :orders, :error

      def self.call(purchase_id:, order_ids:, cart_id: nil, user: nil)
        new(purchase_id:, order_ids:, cart_id:, user:).call
      end

      def initialize(purchase_id:, order_ids:, cart_id:, user:)
        @purchase_id = purchase_id
        @order_ids = Array(order_ids).map(&:to_i)
        @cart_id = cart_id
        @user = user
        @purchase = nil
        @orders = []
        @error = nil
      end

      # Idempotente: el webhook de Wompi, sus reintentos, el polling de status y
      # la conciliación del admin pueden llamar esto varias veces para la misma
      # compra. Solo la primera la confirma, otorga Premium y envía correos.
      def call
        already_confirmed = false

        ActiveRecord::Base.transaction do
          @purchase = Purchase.lock.find(@purchase_id)

          if @user && @purchase.user_id && @purchase.user_id != @user.id
            return failure("Purchase does not belong to current user")
          end

          @orders =
            Order.where(id: @order_ids, purchase_id: @purchase.id)

          return failure("Orders not found for purchase") if @orders.empty?

          if @purchase.confirmed?
            already_confirmed = true
            next
          end

          return failure("Payment is not approved for this purchase") unless @purchase.payments.approved.exists?

          if @purchase.purchase_intent
            @purchase.purchase_intent.update!(status: :completed)
          end

          @purchase.update!(status: :confirmed)
          @orders.each { |order| order.update!(status: :confirmed) }

          Premium::GrantForPurchase.call(purchase: @purchase)
          mark_digital_only_orders_delivered!
          complete_cart!
        end

        send_confirmation_email unless already_confirmed
        self
      rescue ActiveRecord::RecordNotFound => e
        failure(e.message)
      rescue StandardError => e
        Rails.logger.error "Error completing order: #{e.message}"
        failure("Unexpected error completing order")
      end

      def success?
        @error.nil?
      end

      private

      # Una compra solo de productos digitales (plan Premium) no tiene envío:
      # sus órdenes quedan entregadas de inmediato.
      def mark_digital_only_orders_delivered!
        items = @purchase.purchase_items.includes(:product)
        return if items.empty? || items.any? { |item| !item.product.digital? }

        @orders.each { |order| order.update!(status: :delivered) }
      end

      # Cierra el carrito que originó la compra (guardado al preparar la orden),
      # salvo que la clienta ya haya iniciado un checkout más nuevo con ese
      # carrito: entonces se pagó un intento viejo y el carrito sigue en uso.
      # `cart_id` queda solo para compras preparadas antes de ese vínculo.
      def complete_cart!
        intent = @purchase.purchase_intent
        cart = intent&.cart
        return if cart && PurchaseIntent.where(cart:).where("created_at > ?", intent.created_at).exists?

        cart ||= Cart.find_by(id: @cart_id, user_id: @purchase.user_id) if @cart_id
        return unless cart

        cart.update!(status: :completed)
      end

      # El pedido ya quedó confirmado en la transacción anterior; un fallo de
      # email nunca debe revertir ni reportar error en la compra (ver
      # docs/requirements/fase3-personalizacion-objetivos-salud.md §5.2).
      def send_confirmation_email
        if @purchase.user&.email.present?
          OrderMailer.confirmation(@purchase).deliver_later
        end
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue order confirmation email for purchase #{@purchase.id}: #{e.message}"
      ensure
        send_admin_notification_email
      end

      def send_admin_notification_email
        return unless ENV["ADMIN_NOTIFICATION_EMAIL"].present?

        OrderMailer.admin_notification(@purchase).deliver_later
      rescue StandardError => e
        Rails.logger.error "Failed to enqueue admin order notification for purchase #{@purchase.id}: #{e.message}"
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
