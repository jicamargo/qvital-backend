require "test_helper"

module Marketplace
  module Carts
    class UpdateItemTest < ActiveSupport::TestCase
      test "rejects more than the maximum units of a product" do
        level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        user = User.create!(email: "update-item-#{SecureRandom.hex(4)}@example.com", role: "cliente", level:)
        product = Product.create!(name: "Producto #{SecureRandom.hex(4)}", active: true)
        item = Cart.create!(user:).cart_items.create!(product:, quantity: 1, price_snapshot: 1)

        result = UpdateItem.call(user:, cart_item_id: item.id, quantity: CartItem::MAX_QUANTITY + 1)

        assert_match(/máximo/i, result.error)
        assert_equal 1, item.reload.quantity
      end
    end
  end
end
