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

      def self.call(user:, cart_items:, shipping_address:, recipient_info:, selected_date:, shipping_cost:, payment_method: nil, purchase_intent_id: nil)
        new(
          user:,
          cart_items:,
          shipping_address:,
          recipient_info:,
          selected_date:,
          shipping_cost:,
          payment_method:,
          purchase_intent_id:
        ).call
      end

      def initialize(user:, cart_items:, shipping_address:, recipient_info:, selected_date:, shipping_cost:, payment_method:, purchase_intent_id:)
        @user = user
        @cart_items = cart_items || []
        @shipping_address = shipping_address || {}
        @recipient_info = recipient_info || {}
        @selected_date = selected_date
        @shipping_cost = BigDecimal(shipping_cost.to_s)
        @payment_method = payment_method
        @purchase_intent_id = purchase_intent_id
      end

      def call
        return Result.new(error: "User is required") unless @user
        return Result.new(error: "Cart items are required") if @cart_items.empty?

        subtotal = calculate_subtotal
        return Result.new(error: "Total amount must be greater than minimum") if subtotal < MINIMUM_AMOUNT

        tax_amount = BigDecimal("0")
        total_amount = subtotal + @shipping_cost

        result = nil

        ActiveRecord::Base.transaction do
          purchase_intent = find_or_initialize_purchase_intent(total_amount)
          purchase = find_or_initialize_purchase(purchase_intent, total_amount, subtotal, tax_amount)

          rebuild_purchase_items!(purchase)

          order = find_or_initialize_order(purchase, total_amount)

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
        purchase.recipient_name = @recipient_info[:name]
        purchase.recipient_phone = @recipient_info[:phone]

        purchase.save!
        purchase
      end

      def rebuild_purchase_items!(purchase)
        purchase.purchase_items.destroy_all

        @cart_items.each do |item|
          quantity = item[:quantity].to_i
          price = BigDecimal(item[:price].to_s)
          line_subtotal = quantity * price
          line_tax = BigDecimal("0")
          line_total = line_subtotal + line_tax

          purchase.purchase_items.create!(
            product_id: item[:product_id],
            quantity:,
            unit_price: price,
            line_subtotal:,
            line_tax:,
            line_total:,
            metadata: item[:metadata] || {}
          )
        end
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

      def generate_purchase_number
        timestamp = Time.current.strftime("%Y%m%d%H%M%S")
        "PUR-#{timestamp}-#{@user.id}"
      end
    end
  end
end

