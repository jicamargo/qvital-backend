require "test_helper"

module Marketplace
  module Carts
    class RepeatLastOrderTest < ActiveSupport::TestCase
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "repeat-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        @product = create_product(price: 80_000)
      end

      def create_product(price: 50_000, active: true)
        product = Product.create!(name: "Producto #{SecureRandom.hex(4)}", active: active)
        product.product_prices.create!(level: @level, price: price) if price
        product
      end

      def create_purchase(status:, items:, created_at: Time.current)
        intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 1)
        purchase = Purchase.create!(
          purchase_intent: intent, user: @user, total_amount: 1, subtotal_amount: 1, tax_amount: 0,
          shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}", status: status, created_at: created_at
        )
        items.each do |product, quantity|
          PurchaseItem.create!(
            purchase: purchase, product: product, quantity: quantity, unit_price: 1,
            line_subtotal: quantity, line_tax: 0, line_total: quantity
          )
        end
        purchase
      end

      test "adds the items of the last confirmed purchase, ignoring a newer pending one" do
        other = create_product
        create_purchase(status: :confirmed, items: [ [ @product, 2 ] ], created_at: 2.days.ago)
        create_purchase(status: :pending, items: [ [ other, 1 ] ], created_at: 1.day.ago)

        result = RepeatLastOrder.call(user: @user)

        assert result.success?, result.error
        assert_equal [], result.skipped
        assert_equal [ @product.id ], result.cart.cart_items.map(&:product_id)
        item = result.cart.cart_items.first
        assert_equal 2, item.quantity
        assert_equal BigDecimal("80000"), item.price_snapshot
      end

      test "uses the most recent confirmed purchase" do
        other = create_product
        create_purchase(status: :confirmed, items: [ [ other, 1 ] ], created_at: 5.days.ago)
        create_purchase(status: :confirmed, items: [ [ @product, 1 ] ], created_at: 1.day.ago)

        result = RepeatLastOrder.call(user: @user)

        assert_equal [ @product.id ], result.cart.cart_items.map(&:product_id)
      end

      test "caps the quantity at the maximum" do
        AddItem.call(user: @user, product_id: @product.id, quantity: 8)
        create_purchase(status: :confirmed, items: [ [ @product, 5 ] ])

        result = RepeatLastOrder.call(user: @user)

        assert result.success?, result.error
        assert_equal CartItem::MAX_QUANTITY, result.cart.cart_items.first.quantity
        assert_equal [], result.skipped
      end

      test "skips inactive products and products without a price for the level" do
        inactive = create_product(active: false)
        unpriced = create_product(price: nil)
        create_purchase(status: :confirmed, items: [ [ @product, 1 ], [ inactive, 1 ], [ unpriced, 1 ] ])

        result = RepeatLastOrder.call(user: @user)

        assert result.success?, result.error
        assert_equal [ @product.id ], result.cart.cart_items.map(&:product_id)
        assert_equal [ inactive.name, unpriced.name ].sort, result.skipped.sort
      end

      test "succeeds with every item skipped" do
        inactive = create_product(active: false)
        create_purchase(status: :confirmed, items: [ [ inactive, 1 ] ])

        result = RepeatLastOrder.call(user: @user)

        assert result.success?, result.error
        assert_equal [ inactive.name ], result.skipped
        assert_empty result.cart.cart_items
      end

      test "fails when the user has no confirmed purchases" do
        create_purchase(status: :pending, items: [ [ @product, 1 ] ])

        result = RepeatLastOrder.call(user: @user)

        assert_not result.success?
        assert_equal "Aún no tienes pedidos para repetir.", result.error
      end
    end
  end
end
