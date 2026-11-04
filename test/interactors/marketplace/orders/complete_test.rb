require "test_helper"

module Marketplace
  module Orders
    class CompleteTest < ActiveSupport::TestCase
      include ActiveJob::TestHelper

      setup do
        @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "complete-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level)
        AppSetting.current.update!(premium_purchase_threshold: 100_000)
      end

      def add_item(purchase, product, subtotal:, quantity: 1)
        PurchaseItem.create!(
          purchase:, product:, quantity:, unit_price: subtotal / quantity,
          line_subtotal: subtotal, line_tax: 0, line_total: subtotal
        )
      end

      def physical_product
        Product.create!(name: "Batido #{SecureRandom.hex(3)}")
      end

      def plan_product
        Product.create!(name: "Plan #{SecureRandom.hex(3)}", premium_days: 30)
      end

      # Por defecto la compra lleva un único ítem físico por el total; los
      # beneficios Premium se calculan sobre los ítems, no sobre total_amount.
      def build_approved_purchase(total_amount:, physical: true)
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
        add_item(purchase, physical_product, subtotal: total_amount) if physical
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

      test "stacks 30 days on top of the remaining premium time" do
        freeze_time do
          @user.update!(premium_active: true, premium_expires_at: 5.days.from_now)
          purchase, order = build_approved_purchase(total_amount: 150_000)

          Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user)

          assert_equal 35.days.from_now, @user.reload.premium_expires_at
        end
      end

      test "a purchase with only the Premium plan is delivered right away" do
        purchase, order = build_approved_purchase(total_amount: 30_000, physical: false)
        add_item(purchase, plan_product, subtotal: 30_000)

        result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user)

        assert result.success?, result.error
        assert order.reload.delivered?
        assert @user.reload.premium?
      end

      test "a mixed purchase leaves the order confirmed" do
        purchase, order = build_approved_purchase(total_amount: 230_000)
        add_item(purchase, plan_product, subtotal: 30_000)

        Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user)

        assert order.reload.confirmed?
      end

      test "completing the same purchase twice grants days only once" do
        freeze_time do
          purchase, order = build_approved_purchase(total_amount: 30_000, physical: false)
          add_item(purchase, plan_product, subtotal: 30_000)

          2.times { Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: @user) }

          assert_equal 30.days.from_now, @user.reload.premium_expires_at
        end
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

      test "completing an already confirmed purchase again has no side effects" do
        purchase, order = build_approved_purchase(total_amount: 150_000)
        Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)
        first_expiry = @user.reload.premium_expires_at

        travel 1.hour do
          assert_no_enqueued_jobs do
            result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)
            assert result.success?, result.error
          end
        end

        assert_equal first_expiry, @user.reload.premium_expires_at
      end

      test "closes the cart that originated the purchase, not a newer open cart" do
        purchase, order = build_approved_purchase(total_amount: 150_000)
        purchase_cart = Cart.create!(user: @user)
        purchase.purchase_intent.update!(cart: purchase_cart)
        newer_cart = Cart.create!(user: @user)

        Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)

        assert purchase_cart.reload.completed?
        assert newer_cart.reload.open?
      end

      test "never approves a mock payment, even with the mock flag on" do
        purchase, order = build_approved_purchase(total_amount: 150_000)
        purchase.payments.update_all(provider: "mock_provider", status: Payment.statuses[:pending])
        ENV["MARKETPLACE_MOCK_AUTO_APPROVE"] = "true"

        result = Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)

        assert_match(/not approved/i, result.error)
      ensure
        ENV.delete("MARKETPLACE_MOCK_AUTO_APPROVE")
      end

      test "does not close the cart when a newer checkout of that cart is pending" do
        purchase, order = build_approved_purchase(total_amount: 150_000)
        cart = Cart.create!(user: @user)
        purchase.purchase_intent.update!(cart:)
        PurchaseIntent.create!(user: @user, cart:, external_reference: SecureRandom.uuid, total_amount: 1)

        Complete.call(purchase_id: purchase.id, order_ids: [ order.id ], cart_id: nil, user: nil)

        assert cart.reload.open?
      end
    end
  end
end
