module Marketplace
  module Carts
    class AddItem
      attr_reader :cart, :error

      def self.call(user:, product_id:, quantity:, price_snapshot:)
        new(user: user, product_id: product_id, quantity: quantity, price_snapshot: price_snapshot).call
      end

      def initialize(user:, product_id:, quantity:, price_snapshot:)
        @user = user
        @product_id = product_id
        @quantity = quantity.to_i
        # Dejamos que ActiveRecord haga el cast al tipo decimal de la columna
        @price_snapshot = price_snapshot
        @cart = nil
        @error = nil
      end

      def call
        puts "🚨🚨🚨 AddItem#call start - user=#{@user&.id} product_id=#{@product_id} quantity=#{@quantity} price_snapshot=#{@price_snapshot.inspect}"
        return failure('User is required') unless @user
        return failure('Product is required') unless @product_id
        return failure('Quantity must be greater than 0') unless @quantity.positive?

        ActiveRecord::Base.transaction do
          puts "🚨🚨🚨 AddItem#call inside transaction BEFORE find_or_create_open_cart!"
          @cart = find_or_create_open_cart!
          puts "🚨🚨🚨 AddItem#call AFTER find_or_create_open_cart! cart_id=#{@cart.id}"
          item = @cart.cart_items.find_or_initialize_by(product_id: @product_id)
          puts "🚨🚨🚨 AddItem#call item before update id=#{item.id.inspect} qty=#{item.quantity.inspect} new_record?=#{item.new_record?}"

          if item.new_record?
            # Primera vez que se agrega este producto al carrito:
            # ignoramos el default de la BD y usamos exactamente la cantidad del request.
            item.quantity = @quantity
          else
            # Ya existía: sumamos cantidades como indica el SDD.
            item.quantity = item.quantity.to_i + @quantity
          end
          item.price_snapshot = @price_snapshot
          puts "🚨🚨🚨 AddItem#call item before save id=#{item.id.inspect} qty=#{item.quantity.inspect} price_snapshot=#{item.price_snapshot.inspect}"
          item.save!
          puts "🚨🚨🚨 AddItem#call item saved OK id=#{item.id.inspect}"
        end

        # Recargar carrito con asociaciones necesarias para evitar N+1 al serializar
        @cart = Cart.with_marketplace_includes.find(@cart.id)

        self
      rescue ActiveRecord::RecordInvalid => e
        puts "🚨🚨🚨 AddItem#call ActiveRecord::RecordInvalid: #{e.class.name} - #{e.message}"
        failure(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        puts "🚨🚨🚨 AddItem#call StandardError: #{e.class.name} - #{e.message}"
        puts "🚨🚨🚨 AddItem#call backtrace first: #{e.backtrace&.first}"
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

