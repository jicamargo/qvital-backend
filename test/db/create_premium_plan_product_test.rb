require "test_helper"
require Rails.root.join("db/migrate/20261104120100_create_premium_plan_product.rb")

class CreatePremiumPlanProductTest < ActiveSupport::TestCase
  setup do
    Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
    Level.find_or_create_by!(name: "Mayorista") { |l| l.priority = 6 }
    Product.where(sku: Product::PREMIUM_PLAN_SKU).destroy_all
  end

  def run_migration
    silence_stream { CreatePremiumPlanProduct.new.up }
  end

  def silence_stream
    original = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    yield
  ensure
    ActiveRecord::Migration.verbose = original
  end

  test "creates the plan with a 30.000 price for every level" do
    run_migration

    product = Product.find_by!(sku: Product::PREMIUM_PLAN_SKU)
    assert_equal "Plan Premium x 1 mes", product.name
    assert_equal 30, product.premium_days
    assert product.active
    assert_nil product.category_id
    assert product.description.present?
    assert_equal Level.count, ProductPrice.where(product: product).count
    assert_equal [ 30_000 ], ProductPrice.where(product: product).pluck(:price).uniq.map(&:to_i)
  end

  test "running it twice keeps a single plan" do
    run_migration
    run_migration

    assert_equal 1, Product.where(sku: Product::PREMIUM_PLAN_SKU).count
  end

  test "does not overwrite a price edited by the admin" do
    run_migration
    product = Product.find_by!(sku: Product::PREMIUM_PLAN_SKU)
    price = ProductPrice.find_by!(product: product, level: Level.first)
    price.update!(price: 35_000)

    run_migration

    assert_equal 35_000, price.reload.price.to_i
  end

  test "adds a price for a level created later" do
    run_migration
    level = Level.create!(name: "Nivel nuevo", priority: 99)

    run_migration

    product = Product.find_by!(sku: Product::PREMIUM_PLAN_SKU)
    assert_equal 30_000, ProductPrice.find_by!(product: product, level: level).price.to_i
  end
end
