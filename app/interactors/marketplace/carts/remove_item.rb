module Marketplace
  module Carts
    class RemoveItem
      attr_reader :cart, :error

      def self.call(user:, cart_item_id:)
        new(user: user, cart_item_id: cart_item_id).call
      end

      def initialize(user:, cart_item_id:)
        @user = user
        @cart_item_id = cart_item_id
        @cart = nil
        @error = nil
      end

      def call
        return failure('User is required') unless @user
        return failure('Cart item is required') unless @cart_item_id

        ActiveRecord::Base.transaction do
          item = CartItem.joins(:cart).where(id: @cart_item_id, carts: { user_id: @user.id }).first
          return failure('Cart item not found') unless item

          @cart = item.cart
          item.destroy!
        end

        # Recargar carrito con asociaciones necesarias para evitar N+1 al serializar
        @cart = Cart.with_marketplace_includes.find(@cart.id) if @cart

        self
      rescue StandardError => e
        Rails.logger.error "Error removing cart item: #{e.message}"
        failure('Unexpected error removing cart item')
      end

      def success?
        @error.nil?
      end

      private

      def failure(message)
        @error = message
        self
      end
    end
  end
end

