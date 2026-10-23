module Marketplace
  module Carts
    class AddItem
      attr_reader :cart, :error

      def self.call(user:, product_id:, quantity:)
        new(user: user, product_id: product_id, quantity: quantity).call
      end

      def initialize(user:, product_id:, quantity:)
        @user = user
        @product_id = product_id
        @quantity = quantity.to_i
        @cart = nil
        @error = nil
      end

      def call
        return failure('User is required') unless @user
        return failure('Product is required') unless @product_id
        return failure('Quantity must be greater than 0') unless @quantity.positive?

        product = Product.active.find_by(id: @product_id)
        # El precio lo pone el servidor según el nivel del usuario, nunca el request.
        price = product&.price_for_level(@user.level_id)
        return failure('Este producto ya no está disponible.') unless price

        ActiveRecord::Base.transaction do
          @cart = find_or_create_open_cart!
          item = @cart.cart_items.find_or_initialize_by(product_id: product.id)

          if item.new_record?
            # Primera vez que se agrega este producto al carrito:
            # ignoramos el default de la BD y usamos exactamente la cantidad del request.
            item.quantity = @quantity
          else
            # Ya existía: sumamos cantidades como indica el SDD.
            item.quantity = item.quantity.to_i + @quantity
          end

          if item.quantity > CartItem::MAX_QUANTITY
            return failure("Puedes pedir máximo #{CartItem::MAX_QUANTITY} unidades de este producto.")
          end

          item.price_snapshot = price
          item.save!
        end

        # Recargar carrito con asociaciones necesarias para evitar N+1 al serializar
        @cart = Cart.with_marketplace_includes.find(@cart.id)

        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error adding item to cart: #{e.class.name} - #{e.message}"
        failure('Unexpected error adding item to cart')
      end

      def success?
        @error.nil?
      end

      private

      def find_or_create_open_cart!
        Cart.for_user(@user.id).open.first_or_create!
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
