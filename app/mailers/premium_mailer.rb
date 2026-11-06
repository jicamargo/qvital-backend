class PremiumMailer < ApplicationMailer
  MONTHS = %w[enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre].freeze

  # Aviso de que el Premium vence pronto, con botón para repetir el último
  # pedido (o comprar el Plan Premium si no hay productos físicos).
  def reminder(user)
    @user = user
    @first_name = user.name.to_s.split.first&.capitalize
    @frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:3010")

    last_purchase = Purchase.confirmed.where(user: user).order(created_at: :desc).first
    @items = last_purchase ? last_purchase.purchase_items.includes(:product).reject { |i| i.product.digital? } : []
    @plan = Product.find_by(sku: Product::PREMIUM_PLAN_SKU)
    @plan_url = @plan ? "#{@frontend_url}/marketplace/#{@plan.id}" : "#{@frontend_url}/premium"
    @repeat_url = "#{@frontend_url}/marketplace/repetir"

    mail(to: user.email, subject: "Tu Premium vence el #{spanish_date(user.premium_expires_at)}")
  end

  private

  def spanish_date(time)
    date = time.in_time_zone("America/Bogota")
    "#{date.day} de #{MONTHS[date.month - 1]}"
  end
end
