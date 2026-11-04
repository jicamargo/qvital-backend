require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
    @user = User.create!(
      email: "order-mailer-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: level, name: "Ana Pérez"
    )
  end

  def build_purchase(products:, shipping_address:)
    intent = PurchaseIntent.create!(user: @user, external_reference: SecureRandom.uuid, total_amount: 1)
    purchase = Purchase.create!(
      purchase_intent: intent, user: @user, total_amount: 154_000, subtotal_amount: 1, tax_amount: 0,
      shipping_cost: 0, status: :confirmed, purchase_number: "PUR-#{SecureRandom.hex(6)}",
      recipient_name: "Rosa Gómez", recipient_phone: "3001112233", shipping_address: shipping_address
    )
    products.each do |product|
      PurchaseItem.create!(purchase:, product:, quantity: 2, unit_price: 1, line_subtotal: 2, line_tax: 0, line_total: 2)
    end
    purchase
  end

  def approve_payment(purchase, id)
    payment = Payment.create!(purchase: purchase, external_reference: SecureRandom.uuid, provider: "wompi", provider_payment_id: id, status: :approved, amount: 154_000)
    payment.update_columns(updated_at: Time.utc(2026, 11, 4, 15, 30))
  end

  def bodies(mail)
    [ mail.html_part.body.to_s, mail.text_part.body.to_s ]
  end

  test "mixed purchase lists physical items, recipient, address lines, payment and admin link" do
    shake = Product.create!(name: "Batido", sku: "T7-#{SecureRandom.hex(3)}", flavor: "Vainilla")
    plain = Product.create!(name: "Té", flavor: "")
    plan = Product.create!(name: "Plan Premium", sku: "PLAN-X-#{SecureRandom.hex(3)}", premium_days: 30)
    purchase = build_purchase(
      products: [ shake, plain, plan ],
      shipping_address: { "street" => "Calle 1 # 2-3", "addressDetails" => "Apto 401", "locality" => "Chapinero",
                          "city" => "Bogotá", "state" => "Cundinamarca", "zipCode" => "110111", "phone" => "3009998877" }
    )
    approve_payment(purchase, "wompi-123")
    order = Order.create!(purchase: purchase, total_amount: 154_000)

    mail = OrderMailer.admin_notification(purchase)

    assert_equal "Nuevo pedido #{purchase.purchase_number} — QVITAL", mail.subject
    bodies(mail).each do |body|
      assert_includes body, "#{shake.sku} · Batido · Vainilla · x2"
      assert_includes body, "Té · x2"
      assert_not_includes body, plan.sku
      assert_includes body, "Rosa Gómez"
      assert_includes body, "3001112233"
      assert_includes body, "ID Wompi: wompi-123"
      assert_includes body, "154,000"
      assert_includes body, "04/11/2026 10:30"
      assert_includes body, "Código postal: 110111"
      assert_includes body, "#{ENV.fetch("FRONTEND_URL", "http://localhost:3010")}/admin/orders/#{order.id}"
    end

    text = mail.text_part.body.to_s
    [ "Calle 1 # 2-3", "Apto 401", "Chapinero", "Bogotá, Cundinamarca", "Código postal: 110111" ].each do |line|
      assert_match(/^#{Regexp.escape(line)}$/, text)
    end
  end

  test "digital-only purchase is flagged and has no shipping section" do
    plan = Product.create!(name: "Plan Premium", sku: "PLAN-Y-#{SecureRandom.hex(3)}", premium_days: 30)
    purchase = build_purchase(products: [ plan ], shipping_address: { "phone" => "3009998877" })
    purchase.update!(recipient_phone: nil)

    mail = OrderMailer.admin_notification(purchase)

    assert mail.subject.end_with?("(Plan Premium, sin envío)")
    bodies(mail).each do |body|
      assert_not_includes body, "Envío"
      assert_not_includes body, "Enviar a"
      assert_not_includes body, "ID Wompi"
    end
  end

  test "recipient phone falls back to the shipping address phone" do
    purchase = build_purchase(products: [ Product.create!(name: "Té") ], shipping_address: { "phone" => "3009998877" })
    purchase.update!(recipient_phone: nil)

    assert_includes OrderMailer.admin_notification(purchase).text_part.body.to_s, "Teléfono: 3009998877"
  end

  test "shipped email with tracking shows carrier, number, link and order url" do
    shake = Product.create!(name: "Batido")
    plan = Product.create!(name: "Plan Premium", sku: "PLAN-S-#{SecureRandom.hex(3)}", premium_days: 30)
    purchase = build_purchase(products: [ shake, plan ], shipping_address: {})
    order = Order.create!(
      purchase: purchase, total_amount: 1, status: :shipped,
      tracking_info: { "carrier" => "Servientrega", "tracking_number" => "123", "tracking_url" => "https://x.co/123" }
    )

    mail = OrderMailer.shipped(order)

    assert_equal "¡Tu pedido #{purchase.purchase_number} va en camino!", mail.subject
    assert_equal [ @user.email ], mail.to
    bodies(mail).each do |body|
      assert_includes body, "Servientrega"
      assert_includes body, "123"
      assert_includes body, "Batido x2"
      assert_not_includes body, "Plan Premium"
      assert_includes body, "/marketplace/orders/#{order.id}"
    end
    assert_includes mail.html_part.body.to_s, "Rastrear mi pedido"
    assert_includes mail.html_part.body.to_s, "https://x.co/123"
  end

  test "shipped email without tracking promises the guide number soon" do
    purchase = build_purchase(products: [ Product.create!(name: "Té") ], shipping_address: {})
    order = Order.create!(purchase: purchase, total_amount: 1, status: :shipped)

    bodies(OrderMailer.shipped(order)).each do |body|
      assert_includes body, "pronto te compartimos el número de guía"
      assert_not_includes body, "Rastrear mi pedido"
    end
  end
end
