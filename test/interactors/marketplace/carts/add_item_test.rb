require "test_helper"

module Marketplace
  module Carts
    class AddItemTest < ActiveSupport::TestCase
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "add-item-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        @product = Product.create!(name: "Producto #{SecureRandom.hex(4)}", active: true)
        @product.product_prices.create!(level: @level, price: 80_000)
      end

      test "stores the database price for the user's level" do
        result = AddItem.call(user: @user, product_id: @product.id, quantity: 1)

        assert result.success?, result.error
        assert_equal BigDecimal("80000"), result.cart.cart_items.first.price_snapshot
      end

      test "rejects an inactive product" do
        @product.update!(active: false)

        result = AddItem.call(user: @user, product_id: @product.id, quantity: 1)

        assert_match(/disponible/i, result.error)
      end

      test "rejects going over the maximum units of a product" do
        AddItem.call(user: @user, product_id: @product.id, quantity: CartItem::MAX_QUANTITY)

        result = AddItem.call(user: @user, product_id: @product.id, quantity: 1)

        assert_match(/máximo/i, result.error)
      end
    end
  end
end
