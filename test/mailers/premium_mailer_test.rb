require "test_helper"

class PremiumMailerTest < ActionMailer::TestCase
  setup do
    level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
    @user = User.create!(
      email: "premium-mailer-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: level,
      name: "maría josé", premium_active: true,
      premium_expires_at: Time.utc(2026, 11, 4, 3, 0) # 3 nov 22:00 en Bogotá
    )
  end

  def create_purchase(status:, products:)
    intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 1)
    purchase = Purchase.create!(
      purchase_intent: intent, user: @user, total_amount: 1, subtotal_amount: 1, tax_amount: 0,
      shipping_cost: 0, status: status, purchase_number: "PUR-#{SecureRandom.hex(6)}"
    )
    products.each do |product|
      PurchaseItem.create!(purchase:, product:, quantity: 2, unit_price: 1, line_subtotal: 2, line_tax: 0, line_total: 2)
    end
    purchase
  end

  def physical(name = "Batido Vainilla #{SecureRandom.hex(3)}")
    Product.create!(name: name)
  end

  def plan
    Product.find_by(sku: Product::PREMIUM_PLAN_SKU) ||
      Product.create!(name: "Plan Premium", sku: Product::PREMIUM_PLAN_SKU, premium_days: 30)
  end

  test "subject has the Spanish date in Bogota time" do
    mail = PremiumMailer.reminder(@user)

    assert_equal "Tu Premium vence el 3 de noviembre", mail.subject
    assert_equal [ @user.email ], mail.to
  end

  test "greets by capitalized first name, or plainly without a name" do
    assert_includes PremiumMailer.reminder(@user).text_part.body.to_s, "Hola, María:"

    @user.name = nil
    body = PremiumMailer.reminder(@user).text_part.body.to_s
    assert_includes body, "Hola:"
    assert_not_includes body, "Hola,"
  end

  test "last confirmed purchase with physical items offers repeating it" do
    product = physical("Batido Fresa")
    create_purchase(status: :confirmed, products: [ product, plan ])

    mail = PremiumMailer.reminder(@user)

    [ mail.html_part, mail.text_part ].each do |part|
      body = part.body.to_s
      assert_includes body, "Repetir mi último pedido"
      assert_includes body, "/marketplace/repetir"
      assert_includes body, "Batido Fresa"
      assert_not_includes body, "Plan Premium x"
    end
  end

  test "only the most recent confirmed purchase is listed; pending ones are ignored" do
    create_purchase(status: :confirmed, products: [ physical("Producto Viejo") ])
    create_purchase(status: :confirmed, products: [ physical("Producto Nuevo") ])
    create_purchase(status: :pending, products: [ physical("Producto Pendiente") ])

    body = PremiumMailer.reminder(@user).text_part.body.to_s

    assert_includes body, "Producto Nuevo"
    assert_not_includes body, "Producto Viejo"
    assert_not_includes body, "Producto Pendiente"
  end

  test "digital-only last purchase offers the plan product page" do
    create_purchase(status: :confirmed, products: [ plan ])

    body = PremiumMailer.reminder(@user).html_part.body.to_s

    assert_includes body, "Comprar el Plan Premium"
    assert_not_includes body, "Repetir mi último pedido"
    assert_includes body, "/marketplace/#{plan.id}"
  end

  test "no purchases offers the plan product page" do
    body = PremiumMailer.reminder(@user).text_part.body.to_s

    assert_includes body, "Comprar el Plan Premium"
    assert_not_includes body, "Repetir mi último pedido"
  end

  test "falls back to /premium when the plan product does not exist" do
    Product.where(sku: Product::PREMIUM_PLAN_SKU).delete_all

    body = PremiumMailer.reminder(@user).text_part.body.to_s

    assert_includes body, "/premium"
  end
end
