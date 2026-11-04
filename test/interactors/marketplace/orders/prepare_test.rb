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

      def digital_cart!
        plan = Product.create!(name: "Plan #{SecureRandom.hex(4)}", sku: "PLAN-#{SecureRandom.hex(4)}", active: true, premium_days: 30)
        plan.product_prices.create!(level: @level, price: 30_000)
        @cart.cart_items.create!(product: plan, quantity: 1, price_snapshot: 30_000)
        plan
      end

      test "digital-only cart needs no shipping address or date" do
        digital_cart!

        result = prepare(shipping_address: { phone: "3000000000" }, selected_date: nil)

        assert_nil result.error
        assert_equal BigDecimal("30000"), result.purchase.total_amount
        assert_nil result.order.shipping_date_estimated
      end

      test "digital-only cart accepts string keys for the phone" do
        digital_cart!

        assert_nil prepare(shipping_address: { "phone" => "3000000000" }, selected_date: nil).error
      end

      test "digital-only cart requires a phone" do
        digital_cart!

        assert_equal "Ingresa un teléfono de contacto.", prepare(shipping_address: {}, selected_date: nil).error
      end

      test "digital-only cart requires a name" do
        digital_cart!

        result = prepare(shipping_address: { phone: "3000000000" }, recipient_info: { name: " " }, selected_date: nil)

        assert_equal "Ingresa tu nombre.", result.error
      end

      test "mixed cart still validates the shipping address" do
        digital_cart!
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)

        result = prepare(shipping_address: {})

        assert_match(/departamento/i, result.error)
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

      test "a new checkout never rewrites a previous purchase" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)
        first = prepare
        @cart.cart_items.first.update!(quantity: 3)

        second = prepare

        refute_equal first.purchase_intent.id, second.purchase_intent.id
        assert_equal BigDecimal("100000"), first.purchase.reload.total_amount
      end

      test "cancels older pending purchase intents of the same cart" do
        @cart.cart_items.create!(product: @product, quantity: 1, price_snapshot: 100_000)
        first = prepare

        prepare

        assert first.purchase_intent.reload.cancelled?
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
