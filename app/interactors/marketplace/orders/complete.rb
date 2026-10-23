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

          grant_premium_if_qualifies!
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

      # Cierra el carrito que originó la compra (guardado al preparar la orden).
      # `cart_id` queda solo para compras preparadas antes de ese vínculo.
      def complete_cart!
        cart = @purchase.purchase_intent&.cart
        cart ||= Cart.find_by(id: @cart_id, user_id: @purchase.user_id) if @cart_id
        return unless cart

        cart.update!(status: :completed)
      end

      # Beneficio Premium (no es una suscripción): toda compra confirmada con
      # total >= al umbral configurado (Admin > Configuración) le da al
      # usuario acceso Premium por 30 días desde este momento — se reinicia
      # la ventana en cada compra que califique, sin acumular.
      def grant_premium_if_qualifies!
        user = @purchase.user
        return unless user

        threshold = AppSetting.current.premium_purchase_threshold
        return unless @purchase.total_amount >= threshold

        @purchase.update!(premium_granted: true)
        user.update!(premium_active: true, premium_expires_at: 30.days.from_now)
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
