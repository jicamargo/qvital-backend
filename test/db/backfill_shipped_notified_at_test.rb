require "test_helper"
require Rails.root.join("db/migrate/20261104120200_backfill_shipped_notified_at.rb")

class BackfillShippedNotifiedAtTest < ActiveSupport::TestCase
  def make_order(status)
    intent = PurchaseIntent.create!(external_reference: SecureRandom.uuid, total_amount: 1)
    purchase = Purchase.create!(
      purchase_intent: intent, total_amount: 1, subtotal_amount: 1, tax_amount: 0,
      shipping_cost: 0, purchase_number: "PUR-#{SecureRandom.hex(6)}"
    )
    Order.create!(purchase: purchase, total_amount: 1, status: status)
  end

  def run_migration
    original = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    BackfillShippedNotifiedAt.new.up
  ensure
    ActiveRecord::Migration.verbose = original
  end

  test "marks shipped and delivered orders, leaves the rest NULL, and is idempotent" do
    shipped = make_order(:shipped)
    delivered = make_order(:delivered)
    pending = make_order(:pending)
    confirmed = make_order(:confirmed)
    shipped.update_columns(updated_at: Time.utc(2026, 10, 1, 12))

    run_migration
    run_migration

    assert_equal Time.utc(2026, 10, 1, 12), shipped.reload.shipped_notified_at
    assert delivered.reload.shipped_notified_at.present?
    assert_nil pending.reload.shipped_notified_at
    assert_nil confirmed.reload.shipped_notified_at
  end
end
