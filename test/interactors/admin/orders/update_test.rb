require "test_helper"

module Admin
  module Orders
    class UpdateTest < ActiveSupport::TestCase
      setup do
        intent = PurchaseIntent.create!(external_reference: SecureRandom.uuid, total_amount: 50_000)
        @purchase =
          Purchase.create!(
            purchase_intent: intent, total_amount: 50_000, subtotal_amount: 50_000,
            tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
          )
        @order = Order.create!(purchase: @purchase, total_amount: 50_000)
      end

      test "cannot move an unpaid order forward" do
        result = Update.call(id: @order.id, params: { status: "confirmed" })

        assert_match(/pago/i, result.error)
        assert @order.reload.pending?
      end

      test "can cancel an unpaid order" do
        result = Update.call(id: @order.id, params: { status: "cancelled" })

        assert result.success?, result.error
        assert @order.reload.cancelled?
      end

      test "can ship a paid order" do
        Payment.create!(purchase: @purchase, external_reference: "ref", provider: "wompi", status: :approved, amount: 50_000)

        result = Update.call(id: @order.id, params: { status: "shipped" })

        assert result.success?, result.error
        assert @order.reload.shipped?
      end
    end
  end
end
