module Marketplace
  module Orders
    class Prepare
      Result = Struct.new(
        :purchase_intent,
        :purchase,
        :order,
        :error,
        keyword_init: true
      )

      MINIMUM_AMOUNT = BigDecimal("0")

      def self.call(user:, cart_items:, shipping_address:, recipient_info:, selected_date:, shipping_cost:, payment_method: nil, purchase_intent_id: nil, update_user_profile: false, medical_disclaimer_accepted: false)
        new(
          user:,
          cart_items:,
          shipping_address:,
          recipient_info:,
          selected_date:,
          shipping_cost:,
          payment_method:,
          purchase_intent_id:,
          update_user_profile:,
          medical_disclaimer_accepted:
        ).call
      end

      def initialize(user:, cart_items:, shipping_address:, recipient_info:, selected_date:, shipping_cost:, payment_method:, purchase_intent_id:, update_user_profile:, medical_disclaimer_accepted: false)
        @user = user
        @cart_items = cart_items || []
        @shipping_address = shipping_address || {}
        @recipient_info = recipient_info || {}
        @selected_date = selected_date
        @shipping_cost = BigDecimal(shipping_cost.to_s)
        @payment_method = payment_method
        @purchase_intent_id = purchase_intent_id
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
        return Result.new(error: "Cart items are required") if @cart_items.empty?

        address_errors = ::Colombia::AddressValidator.call(@shipping_address)
        return Result.new(error: address_errors.join(". ")) if address_errors.any?

        validate_cart_products!

        subtotal = calculate_subtotal
        return Result.new(error: "Total amount must be greater than minimum") if subtotal < MINIMUM_AMOUNT

        tax_amount = BigDecimal("0")
        total_amount = subtotal + @shipping_cost

        result = nil

        ActiveRecord::Base.transaction do
          purchase_intent = find_or_initialize_purchase_intent(total_amount)
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
      rescue ActiveRecord::RecordNotFound => e
        Result.new(error: e.message)
      rescue StandardError => e
        Rails.logger.error "Error preparing order: #{e.message}"
        Result.new(error: "Unexpected error preparing order")
      end

      private

      def calculate_subtotal
        @cart_items.sum do |item|
          quantity = item[:quantity].to_i
          price = BigDecimal(item[:price].to_s)
          quantity * price
        end
      end

      def find_or_initialize_purchase_intent(total_amount)
        purchase_intent =
          if @purchase_intent_id
            PurchaseIntent.where(id: @purchase_intent_id, user_id: @user.id).first
          end

        purchase_intent ||=
          PurchaseIntent.create!(
            user: @user,
            company_id: nil,
            external_reference: SecureRandom.uuid,
            status: :pending,
            total_amount:
          )

        purchase_intent.update!(total_amount:) if purchase_intent.total_amount != total_amount

        purchase_intent
      end

      def find_or_initialize_purchase(purchase_intent, total_amount, subtotal, tax_amount)
        purchase =
          Purchase.where(purchase_intent:, user: @user).first_or_initialize

        purchase.total_amount = total_amount
        purchase.subtotal_amount = subtotal
        purchase.tax_amount = tax_amount
        purchase.shipping_cost = @shipping_cost
        purchase.status ||= :pending
        purchase.purchase_number ||= generate_purchase_number
        purchase.shipping_address = @shipping_address
        purchase.recipient_name = recipient_full_name
        purchase.recipient_phone = @recipient_info[:phone]
        purchase.medical_disclaimer_accepted_at ||= Time.current if @medical_disclaimer_accepted

        purchase.save!
        purchase
      end

      def validate_cart_products!
        product_ids = @cart_items.map { |item| item[:product_id].to_i }.uniq
        existing_ids = Product.where(id: product_ids).pluck(:id)
        missing_ids = product_ids - existing_ids
        return if missing_ids.empty?

        raise ActiveRecord::RecordNotFound, "Products not found: #{missing_ids.join(', ')}"
      end

      def rebuild_purchase_items!(purchase)
        purchase.purchase_items.delete_all
        timestamp = Time.current

        rows = @cart_items.map do |item|
          quantity = item[:quantity].to_i
          price = BigDecimal(item[:price].to_s)
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
        "PUR-#{timestamp}-#{@user.id}"
      end
    end
  end
end
