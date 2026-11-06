module Marketplace
  module Carts
    # Vuelve a poner en el carrito los productos de la última compra pagada.
    class RepeatLastOrder
      NO_ORDERS_MESSAGE = 'Aún no tienes pedidos para repetir.'.freeze

      attr_reader :cart, :skipped, :error

      def self.call(user:)
        new(user: user).call
      end

      def initialize(user:)
        @user = user
        @cart = nil
        @skipped = []
        @error = nil
      end

      def call
        return failure('User is required') unless @user

        purchase = Purchase.where(user: @user, status: :confirmed).order(created_at: :desc).first
        return failure(NO_ORDERS_MESSAGE) unless purchase

        ActiveRecord::Base.transaction do
          @cart = Cart.for_user(@user.id).open.first_or_create!
          # Idempotente: si este carrito ya repitió esta compra, no se suma otra vez.
          # Si la clienta lo vació después, la marca ya no aplica y se vuelve a llenar.
          unless @cart.repeated_purchase_id == purchase.id && @cart.cart_items.exists?
            purchase.purchase_items.includes(:product).each { |purchase_item| add_item(purchase_item) }
            @cart.update!(repeated_purchase_id: purchase.id)
          end
        end

        @cart = Cart.with_marketplace_includes.find(@cart.id)

        self
      rescue ActiveRecord::RecordInvalid => e
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        Rails.logger.error "Error repeating last order: #{e.class.name} - #{e.message}"
        failure('Unexpected error repeating last order')
      end

      def success?
        @error.nil?
      end

      private

      def add_item(purchase_item)
        product = purchase_item.product
        # El precio lo pone el servidor según el nivel actual del usuario.
        price = product.active? ? product.price_for_level(@user.level_id) : nil

        unless price
          @skipped << product.name
          return
        end

        item = @cart.cart_items.find_or_initialize_by(product_id: product.id)
        # Un ítem nuevo trae quantity 1 por default de la BD: se ignora.
        current = item.new_record? ? 0 : item.quantity.to_i
        item.quantity = [ current + purchase_item.quantity, CartItem::MAX_QUANTITY ].min
        item.price_snapshot = price
        item.save!
      end

      def failure(message)
        @error = message
        self
      end
    end
  end
end
