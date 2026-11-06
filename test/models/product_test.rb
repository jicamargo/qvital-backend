require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "digital? is true when premium_days is set" do
    assert Product.new(name: "Plan", premium_days: 30).digital?
  end

  test "digital? is false when premium_days is nil" do
    assert_not Product.new(name: "Batido").digital?
  end

  test "premium_days must be greater than zero" do
    assert_not Product.new(name: "Plan", premium_days: 0).valid?
    assert_not Product.new(name: "Plan", premium_days: -5).valid?
    assert Product.new(name: "Plan", premium_days: nil).valid?
    assert Product.new(name: "Plan", premium_days: 30).valid?
  end

  test "digital and physical scopes split products by premium_days" do
    digital = Product.create!(name: "Plan #{SecureRandom.hex(3)}", premium_days: 30)
    physical = Product.create!(name: "Batido #{SecureRandom.hex(3)}")

    assert_includes Product.digital, digital
    assert_not_includes Product.digital, physical
    assert_includes Product.physical, physical
    assert_not_includes Product.physical, digital
  end

  test "PREMIUM_PLAN_SKU is defined" do
    assert_equal "QVITAL-PREMIUM-1M", Product::PREMIUM_PLAN_SKU
  end
end
