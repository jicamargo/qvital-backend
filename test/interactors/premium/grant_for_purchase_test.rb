require "test_helper"

module Premium
  class GrantForPurchaseTest < ActiveSupport::TestCase
    setup do
      level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
      @user = User.create!(email: "grant-test-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: level)
      AppSetting.current.update!(premium_purchase_threshold: 200_000)
      @intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 1)
      @purchase = Purchase.create!(
        purchase_intent: @intent, user: @user, total_amount: 1, subtotal_amount: 1,
        tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
      )
    end

    def add_physical(subtotal)
      product = Product.create!(name: "Batido #{SecureRandom.hex(3)}")
      add_item(product, 1, subtotal)
    end

    def add_plan(quantity = 1)
      product = Product.create!(name: "Plan #{SecureRandom.hex(3)}", premium_days: 30)
      add_item(product, quantity, 30_000 * quantity)
    end

    def add_item(product, quantity, subtotal)
      PurchaseItem.create!(
        purchase: @purchase, product:, quantity:, unit_price: subtotal / quantity,
        line_subtotal: subtotal, line_tax: 0, line_total: subtotal
      )
    end

    test "physical items at the threshold grant 30 days" do
      freeze_time do
        add_physical(200_000)

        assert_equal 30, GrantForPurchase.call(purchase: @purchase)
        assert_equal 30.days.from_now, @user.reload.premium_expires_at
        assert @user.premium_active
        assert @purchase.reload.premium_granted
      end
    end

    test "stacks on the remaining days" do
      freeze_time do
        @user.update!(premium_active: true, premium_expires_at: 5.days.from_now)
        add_physical(200_000)

        GrantForPurchase.call(purchase: @purchase)

        assert_equal 35.days.from_now, @user.reload.premium_expires_at
      end
    end

    test "an expired premium starts from now" do
      freeze_time do
        @user.update!(premium_active: true, premium_expires_at: 3.days.ago)
        add_physical(200_000)

        GrantForPurchase.call(purchase: @purchase)

        assert_equal 30.days.from_now, @user.reload.premium_expires_at
      end
    end

    test "a nil expiry starts from now" do
      freeze_time do
        @user.update!(premium_active: false, premium_expires_at: nil)
        add_physical(200_000)

        GrantForPurchase.call(purchase: @purchase)

        assert_equal 30.days.from_now, @user.reload.premium_expires_at
      end
    end

    test "one plan plus physical items at the threshold grants 60 days" do
      add_physical(200_000)
      add_plan

      assert_equal 60, GrantForPurchase.call(purchase: @purchase)
    end

    test "two plans alone grant 60 days" do
      add_plan(2)

      assert_equal 60, GrantForPurchase.call(purchase: @purchase)
    end

    test "the plan does not count toward the threshold" do
      add_physical(190_000)
      add_plan

      assert_equal 30, GrantForPurchase.call(purchase: @purchase)
    end

    test "physical items below the threshold grant nothing" do
      add_physical(100_000)

      assert_no_changes -> { @user.reload.premium_expires_at } do
        assert_equal 0, GrantForPurchase.call(purchase: @purchase)
      end
      refute @purchase.reload.premium_granted
    end

    test "a purchase without user grants nothing" do
      add_physical(200_000)
      @purchase.update!(user: nil)

      assert_equal 0, GrantForPurchase.call(purchase: @purchase)
    end
  end
end
