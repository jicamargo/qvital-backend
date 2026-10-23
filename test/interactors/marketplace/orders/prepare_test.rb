require "test_helper"

module Marketplace
  module Orders
    class PrepareTest < ActiveSupport::TestCase
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "prepare-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        @product = Product.create!(name: "Producto #{SecureRandom.hex(4)}", sku: "PREP-#{SecureRandom.hex(4)}", active: true)
        @product.product_prices.create!(level: @level, price: 100_000)
        @cart = Cart.create!(user: @user)
      end

      def address
        { street: "Calle 1 # 2-34", city: "Barranquilla", state: "Atlántico", zipCode: "080001", phone: "3000000000" }
      end

      def prepare(**overrides)
        Prepare.call(
          user: @user,
          shipping_address: address,
          recipient_info: { name: "Nombre", last_name: "Apellido" },
          selected_date: (Date.current + 1.day).to_s,
          **overrides
        )
      end

      test "charges the database price for the user's level, not the cart snapshot" do
        @cart.cart_items.create!(product: @product, quantity: 2, price_snapshot: 1)

        result = prepare

        assert_nil result.error
        assert_equal BigDecimal("200000"), result.purchase.total_amount
        assert_equal [ BigDecimal("100000") ], result.purchase.purchase_items.reload.map(&:unit_price)
      end

      test "shipping is always free" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)

        result = prepare

        assert_equal 0, result.purchase.shipping_cost
        assert_equal result.purchase.subtotal_amount, result.purchase.total_amount
      end

      test "rejects an empty cart" do
        assert_match(/carrito/i, prepare.error)
      end

      test "rejects an inactive product" do
        @product.update!(active: false)
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)

        assert_match(/disponible/i, prepare.error)
      end

      test "rejects a product without a price for the user's level" do
        other = Product.create!(name: "Sin precio #{SecureRandom.hex(4)}", active: true)
        @cart.cart_items.create!(product: other, quantity: 1, price_snapshot: 100_000)

        assert_match(/disponible/i, prepare.error)
      end

      test "rejects more than the maximum units of a product" do
        item = @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)
        item.update_column(:quantity, CartItem::MAX_QUANTITY + 1)

        assert_match(/máximo/i, prepare.error)
      end

      test "links the cart to the purchase intent" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)

        assert_equal @cart, prepare.purchase_intent.cart
      end

      test "refuses to modify a purchase that was already paid" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)
        first = prepare
        first.purchase.update!(status: :confirmed)

        result = prepare(purchase_intent_id: first.purchase_intent.id)

        assert_match(/pagad/i, result.error)
        assert_equal BigDecimal("100000"), first.purchase.reload.total_amount
      end

      test "generates distinct purchase numbers within the same second" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)

        travel_to Time.current.change(usec: 0) do
          numbers = 2.times.map { prepare.purchase.purchase_number }
          assert_equal 2, numbers.uniq.size
        end
      end
    end
  end
end
