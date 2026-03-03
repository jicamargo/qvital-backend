module Marketplace
  module Carts
    class UpdateItem
      attr_reader :cart, :error

      def self.call(user:, cart_item_id:, quantity:)
        new(user: user, cart_item_id: cart_item_id, quantity: quantity).call
      end

      def initialize(user:, cart_item_id:, quantity:)
        @user = user
        @cart_item_id = cart_item_id
        @quantity = quantity.to_i
        @cart = nil
        @error = nil
      end

      def call
        return failure('User is required') unless @user
        return failure('Cart item is required') unless @cart_item_id

        ActiveRecord::Base.transaction do
          item = CartItem.joins(:cart).where(id: @cart_item_id, carts: { user_id: @user.id }).first
          return failure('Cart item not found') unless item

          if @quantity <= 0
            @cart = item.cart
            item.destroy!
          else
            item.update!(quantity: @quantity)
            @cart = item.cart
          end
        end

        # Recargar carrito con asociaciones necesarias para evitar N+1 al serializar
        @cart = Cart.with_marketplace_includes.find(@cart.id) if @cart

        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error updating cart item: #{e.message}"
        failure('Unexpected error updating cart item')
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

