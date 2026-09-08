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

      def call
        ActiveRecord::Base.transaction do
          @purchase = Purchase.find(@purchase_id)

          if @user && @purchase.user_id && @purchase.user_id != @user.id
            return failure("Purchase does not belong to current user")
          end

          @orders =
            Order.where(id: @order_ids, purchase_id: @purchase.id)

          return failure("Orders not found for purchase") if @orders.empty?
          return failure("Payment is not approved for this purchase") unless ensure_approved_payment!

          if @purchase.purchase_intent
            @purchase.purchase_intent.update!(status: :completed)
          end

          @purchase.update!(status: :confirmed)
          @orders.each { |order| order.update!(status: :confirmed) }

          grant_premium_if_qualifies!
          complete_cart! if @cart_id
        end

        send_confirmation_email
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

      def ensure_approved_payment!
        return true if @purchase.payments.approved.exists?

        return false unless mock_auto_approve_enabled?

        mock_payment =
          @purchase.payments
                   .where(provider: "mock_provider")
                   .order(updated_at: :desc)
                   .first
        return false unless mock_payment

        mock_payment.update!(
          status: :approved,
          provider_payment_id: mock_payment.provider_payment_id.presence || "mock-#{SecureRandom.uuid}",
          raw_payload: (mock_payment.raw_payload || {}).merge(
            "mock_auto_approved" => true,
            "mock_auto_approved_at" => Time.current.iso8601
          )
        )
        Rails.logger.info "Mock payment auto-approved for purchase #{@purchase.id}"
        true
      end

      def mock_auto_approve_enabled?
        default_value = Rails.env.development? || Rails.env.staging?
        env_value = ENV.fetch("MARKETPLACE_MOCK_AUTO_APPROVE", default_value.to_s)
        ActiveModel::Type::Boolean.new.cast(env_value)
      end

      def complete_cart!
        cart = Cart.find_by(id: @cart_id, user_id: @purchase.user_id)
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
