require "test_helper"

module Admin
  module Orders
    class UpdateTest < ActiveSupport::TestCase
      include ActionMailer::TestHelper

      setup do
        level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "ship-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: level, name: "Ana")
        intent = PurchaseIntent.create!(external_reference: SecureRandom.uuid, total_amount: 50_000)
        @purchase =
          Purchase.create!(
            purchase_intent: intent, total_amount: 50_000, subtotal_amount: 50_000,
            user: @user, tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
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

      def pay!
        Payment.create!(purchase: @purchase, external_reference: "ref", provider: "wompi", status: :approved, amount: 50_000)
      end

      test "shipping a paid order enqueues one email and marks it notified" do
        pay!

        assert_enqueued_emails 1 do
          assert Update.call(id: @order.id, params: { status: "shipped" }).success?
        end
        assert @order.reload.shipped_notified_at.present?
      end

      test "saving again or changing tracking does not resend" do
        pay!
        Update.call(id: @order.id, params: { status: "shipped" })

        assert_no_enqueued_emails do
          Update.call(id: @order.id, params: { status: "shipped" })
          Update.call(id: @order.id, params: { tracking_info: { tracking_number: "999" } })
        end
      end

      test "unpaid order cannot ship and sends nothing" do
        assert_no_enqueued_emails do
          result = Update.call(id: @order.id, params: { status: "shipped" })
          assert_match(/pago/i, result.error)
        end
        assert_nil @order.reload.shipped_notified_at
      end

      test "user without email is skipped" do
        pay!
        @user.update_columns(email: "")

        assert_no_enqueued_emails do
          assert Update.call(id: @order.id, params: { status: "shipped" }).success?
        end
        assert_nil @order.reload.shipped_notified_at
      end

      test "tracking_info keeps only the three fields, trimmed, and drops non-http urls" do
        Update.call(id: @order.id, params: { tracking_info: {
          carrier: " Servientrega ", tracking_number: "123", tracking_url: "javascript:alert(1)", extra: "x"
        } })

        assert_equal({ "carrier" => "Servientrega", "tracking_number" => "123" }, @order.reload.tracking_info)
      end

      test "tracking_info drops blank values and keeps https urls" do
        Update.call(id: @order.id, params: { tracking_info: {
          carrier: "  ", tracking_number: "55", tracking_url: " https://x.co/t/55 "
        } })

        assert_equal({ "tracking_number" => "55", "tracking_url" => "https://x.co/t/55" }, @order.reload.tracking_info)
      end
    end
  end
end
