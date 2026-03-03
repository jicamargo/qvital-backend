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

          if @purchase.purchase_intent
            @purchase.purchase_intent.update!(status: :completed)
          end

          @purchase.update!(status: :confirmed)
          @orders.each { |order| order.update!(status: :confirmed) }

          complete_cart! if @cart_id
        end

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

      def complete_cart!
        cart = Cart.find_by(id: @cart_id, user_id: @purchase.user_id)
        return unless cart

        cart.update!(status: :completed)
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end

