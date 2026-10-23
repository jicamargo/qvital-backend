require "test_helper"

module Marketplace
  module Checkout
    class ReconcileTransactionTest < ActiveSupport::TestCase
      include ActiveJob::TestHelper
      include ActionMailer::TestHelper

      setup do
        level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
        @user = User.create!(email: "reconcile-#{SecureRandom.hex(4)}@example.com", role: "cliente", level:)
        @intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 120_000)
        @purchase =
          Purchase.create!(
            purchase_intent: @intent, user: @user, total_amount: 120_000, subtotal_amount: 120_000,
            tax_amount: 0, shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
          )
        Order.create!(purchase: @purchase, total_amount: 120_000)
        @payment =
          Payment.create!(
            purchase: @purchase, external_reference: @intent.external_reference,
            provider: "wompi", status: :pending, amount: 120_000, currency: "COP"
          )
      end

      def reconcile(status: "APPROVED", amount_in_cents: 12_000_000, currency: "COP", transaction_id: "tx-1")
        ReconcileTransaction.call(
          external_reference: @intent.external_reference,
          provider_payment_id: transaction_id,
          status:,
          amount_in_cents:,
          currency:
        )
      end

      test "an approved transaction for the exact amount confirms the purchase" do
        result = reconcile

        assert result.success?, result.error
        assert @payment.reload.approved?
        assert @purchase.reload.confirmed?
      end

      test "an approved transaction for a different amount is not approved and alerts the admin" do
        ENV["ADMIN_NOTIFICATION_EMAIL"] = "admin@example.com"

        assert_enqueued_emails 1 do
          result = reconcile(amount_in_cents: 100)
          refute result.success?
        end

        refute @payment.reload.approved?
        assert @purchase.reload.pending?
      ensure
        ENV.delete("ADMIN_NOTIFICATION_EMAIL")
      end

      test "an approved transaction in another currency is not approved" do
        refute reconcile(currency: "USD").success?

        refute @payment.reload.approved?
        assert @purchase.reload.pending?
      end

      test "a late declined event does not downgrade an approved payment" do
        reconcile

        reconcile(status: "DECLINED")

        assert @payment.reload.approved?
      end

      test "a repeated mismatched transaction alerts the admin only once" do
        ENV["ADMIN_NOTIFICATION_EMAIL"] = "admin@example.com"

        assert_enqueued_emails 1 do
          2.times { reconcile(amount_in_cents: 100) }
        end
      ensure
        ENV.delete("ADMIN_NOTIFICATION_EMAIL")
      end

      test "a late event for another transaction of the same reference never touches the approved payment" do
        reconcile(transaction_id: "tx-approved")

        reconcile(transaction_id: "tx-declined", status: "DECLINED", amount_in_cents: 1)

        approved = Payment.find_by!(provider_payment_id: "tx-approved")
        assert approved.approved?
        assert_equal BigDecimal("120000"), approved.amount
        assert Payment.find_by!(provider_payment_id: "tx-declined").rejected?
      end
    end
  end
end
