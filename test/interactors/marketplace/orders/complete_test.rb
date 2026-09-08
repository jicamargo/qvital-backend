require "test_helper"

module Marketplace
  module Orders
    class CompleteTest < ActiveSupport::TestCase
      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "complete-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        AppSetting.current.update!(premium_purchase_threshold: 100_000)
      end

      def build_approved_purchase(total_amount:)
        purchase_intent =
          PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: total_amount)
        purchase =
          Purchase.create!(
            purchase_intent:, user: @user, total_amount:, subtotal_amount: total_amount,
            tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
          )
        order = Order.create!(purchase:, total_amount:)
        Payment.create!(
          purchase:, external_reference: purchase_intent.external_reference,
          provider: "wompi", status: :approved, amount: total_amount, currency: "COP"
        )
        [ purchase, order ]
      end

      test "grants premium for 30 days when the purchase total meets the threshold" do
        purchase, order = build_approved_purchase(total_amount: 150_000)

        result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user)

        assert result.success?, result.error
        assert purchase.reload.premium_granted
        assert @user.reload.premium_active
        assert_operator @user.premium_expires_at, :>, 29.days.from_now
        assert @user.premium?
      end

      test "does not grant premium when the purchase total is below the threshold" do
        purchase, order = build_approved_purchase(total_amount: 50_000)

        result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user)

        assert result.success?, result.error
        refute purchase.reload.premium_granted
        refute @user.reload.premium_active
      end

      test "does not grant premium for a purchase with no associated user" do
        purchase_intent = PurchaseIntent.create!(external_reference: SecureRandom.uuid, total_amount: 150_000)
        purchase =
          Purchase.create!(
            purchase_intent:, user: nil, total_amount: 150_000, subtotal_amount: 150_000,
            tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
          )
        order = Order.create!(purchase:, total_amount: 150_000)
        Payment.create!(
          purchase:, external_reference: purchase_intent.external_reference,
          provider: "wompi", status: :approved, amount: 150_000, currency: "COP"
        )

        result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)

        assert result.success?, result.error
        refute purchase.reload.premium_granted
      end
    end
  end
end
