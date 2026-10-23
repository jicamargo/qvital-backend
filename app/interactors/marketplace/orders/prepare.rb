module Marketplace
  module Orders
    # Arma la compra a partir del carrito abierto del usuario en el servidor.
    # Precios, cantidades y envío los decide el backend: nada de eso se toma
    # del request, para que nadie pueda pagar menos de lo que vale el pedido.
    class Prepare
      Result = Struct.new(
        :purchase_intent,
        :purchase,
        :order,
        :error,
        keyword_init: true
      )

      # Herbalife envía sin costo directo a la clienta.
      SHIPPING_COST = BigDecimal("0")

      def self.call(user:, shipping_address:, recipient_info:, selected_date:, payment_method: nil, update_user_profile: false, medical_disclaimer_accepted: false)
        new(
          user:,
          shipping_address:,
          recipient_info:,
          selected_date:,
          payment_method:,
          update_user_profile:,
          medical_disclaimer_accepted:
        ).call
      end

      def initialize(user:, shipping_address:, recipient_info:, selected_date:, payment_method:, update_user_profile:, medical_disclaimer_accepted: false)
        @user = user
        @shipping_address = shipping_address || {}
        @recipient_info = recipient_info || {}
        @selected_date = selected_date
        @payment_method = payment_method
        @update_user_profile = ActiveModel::Type::Boolean.new.cast(update_user_profile)
        # NOTA: no se rechaza (422) todavía si viene en false/ausente — el frontend aún no
        # envía el checkbox de descargo médico (llega en la sub-fase 3.4 frontend). Se
        # persiste la aceptación cuando llega, pero no se hace obligatoria aún para no
        # romper el checkout ya en producción. Endurecer a obligatorio una vez el frontend
        # lo envíe siempre — ver docs/requirements/fase3-personalizacion-objetivos-salud.md §5.1.
        @medical_disclaimer_accepted = ActiveModel::Type::Boolean.new.cast(medical_disclaimer_accepted)
      end

      def call
        return Result.new(error: "User is required") unless @user

        address_errors = ::Colombia::AddressValidator.call(@shipping_address)
        return Result.new(error: address_errors.join(". ")) if address_errors.any?

        @cart = find_open_cart
        return Result.new(error: "Tu carrito está vacío.") if @cart.nil? || @cart.cart_items.empty?

        line_error = build_lines
        return Result.new(error: line_error) if line_error

        subtotal = @lines.sum { |line| line[:quantity] * line[:unit_price] }
        tax_amount = BigDecimal("0")
        total_amount = subtotal + SHIPPING_COST

        result = nil

        ActiveRecord::Base.transaction do
          # Cada intento de pago es una compra nueva: nunca se reescribe una
          # anterior (podría estar pagándose en ese momento). Los intentos
          # pendientes previos del mismo carrito quedan cancelados.
          PurchaseIntent.where(cart: @cart, status: :pending).update_all(status: PurchaseIntent.statuses[:cancelled])
          purchase_intent = create_purchase_intent!(total_amount)
          purchase = find_or_initialize_purchase(purchase_intent, total_amount, subtotal, tax_amount)

          purchase_item_rows = rebuild_purchase_items!(purchase)

          order = find_or_initialize_order(purchase, total_amount)
          rebuild_order_items!(order, purchase_item_rows)
          validate_order_items_subtotal!(purchase_item_rows, purchase)
          update_user_profile_from_checkout! if @update_user_profile

          result =
            Result.new(
              purchase_intent:,
              purchase:,
              order:
            )
        end

        result
      rescue StandardError => e
        Rails.logger.error "Error preparing order: #{e.message}"
        Result.new(error: "Unexpected error preparing order")
      end

      private

      def find_open_cart
        Cart.for_user(@user.id).open
            .includes(cart_items: { product: :product_prices })
            .order(created_at: :desc)
            .first
      end

      # Devuelve un mensaje de error para la clienta, o nil si todo el carrito
      # se puede cobrar. Deja en @lines cantidad y precio vigente de cada ítem.
      def build_lines
        @lines = []

        @cart.cart_items.each do |item|
          product = item.product
          unit_price = product.price_for_level(@user.level_id) if product.active?
          return "#{product.name} ya no está disponible. Quítalo del carrito para continuar." unless unit_price

          unless item.quantity.between?(1, CartItem::MAX_QUANTITY)
            return "Puedes pedir máximo #{CartItem::MAX_QUANTITY} unidades de #{product.name}."
          end

          @lines << { product_id: product.id, quantity: item.quantity, unit_price:, metadata: item.metadata || {} }
        end

        nil
      end

      def create_purchase_intent!(total_amount)
        PurchaseIntent.create!(
          user: @user,
          company_id: nil,
          external_reference: SecureRandom.uuid,
          status: :pending,
          total_amount:,
          cart: @cart
        )
      end

      def find_or_initialize_purchase(purchase_intent, total_amount, subtotal, tax_amount)
        purchase =
          Purchase.where(purchase_intent:, user: @user).first_or_initialize

        purchase.total_amount = total_amount
        purchase.subtotal_amount = subtotal
        purchase.tax_amount = tax_amount
        purchase.shipping_cost = SHIPPING_COST
        purchase.status ||= :pending
        purchase.purchase_number ||= generate_purchase_number
        purchase.shipping_address = @shipping_address
        purchase.recipient_name = recipient_full_name
        purchase.recipient_phone = @recipient_info[:phone]
        purchase.medical_disclaimer_accepted_at ||= Time.current if @medical_disclaimer_accepted

        purchase.save!
        purchase
      end

      def rebuild_purchase_items!(purchase)
        purchase.purchase_items.delete_all
        timestamp = Time.current

        rows = @lines.map do |item|
          quantity = item[:quantity]
          price = item[:unit_price]
          line_subtotal = quantity * price
          line_tax = BigDecimal("0")
          line_total = line_subtotal + line_tax

          {
            purchase_id: purchase.id,
            product_id: item[:product_id],
            quantity:,
            unit_price: price,
            line_subtotal:,
            line_tax:,
            line_total:,
            metadata: item[:metadata] || {},
            created_at: timestamp,
            updated_at: timestamp
          }
        end

        PurchaseItem.insert_all!(rows) if rows.any?
        rows
      end

      def find_or_initialize_order(purchase, total_amount)
        order =
          Order.where(purchase:).first_or_initialize

        order.total_amount = total_amount
        order.status ||= :pending
        order.shipping_date_estimated = @selected_date

        order.save!
        order
      end

      def rebuild_order_items!(order, purchase_item_rows)
        order.order_items.delete_all

        rows = purchase_item_rows.map do |item|
          {
            order_id: order.id,
            product_id: item[:product_id],
            quantity: item[:quantity],
            price: item[:unit_price],
            metadata: item[:metadata] || {},
            created_at: item[:created_at],
            updated_at: item[:updated_at]
          }
        end

        OrderItem.insert_all!(rows) if rows.any?
      end

      def validate_order_items_subtotal!(purchase_item_rows, purchase)
        order_items_subtotal =
          purchase_item_rows.sum do |item|
            BigDecimal(item[:line_subtotal].to_s)
          end

        expected_subtotal = BigDecimal(purchase.subtotal_amount.to_s)
        return if order_items_subtotal == expected_subtotal

        raise "Order items subtotal mismatch for purchase #{purchase.id}"
      end

      def recipient_full_name
        [@recipient_info[:name], @recipient_info[:last_name]]
          .map { |part| part.to_s.strip }
          .reject(&:blank?)
          .join(" ")
      end

      def update_user_profile_from_checkout!
        user_updates = {}
        shipping = @shipping_address.respond_to?(:to_h) ? @shipping_address.to_h : {}
        recipient_name = @recipient_info[:name].to_s.strip
        recipient_last_name = @recipient_info[:last_name].to_s.strip
        shipping_phone = shipping["phone"].presence || shipping[:phone].presence
        address_only = shipping.except("phone", :phone)

        user_updates[:phone] = shipping_phone if shipping_phone.present?
        user_updates[:address] = address_only if address_only.present?
        user_updates[:name] = recipient_name if recipient_name.present?
        user_updates[:last_name] = recipient_last_name if recipient_last_name.present?

        return if user_updates.empty?

        @user.update!(user_updates)
      end

      def generate_purchase_number
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        "PUR-#{timestamp}-#{@user.id}-#{SecureRandom.hex(2).upcase}"
      end
    end
  end
end
