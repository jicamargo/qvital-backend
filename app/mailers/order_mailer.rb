class OrderMailer < ApplicationMailer
  # Confirmación de pedido para el cliente.
  # Ver docs/requirements/fase3-personalizacion-objetivos-salud.md §5.2.
  def confirmation(purchase)
    @purchase = purchase
    @order = purchase.order
    @items = purchase.purchase_items.includes(:product)

    mail(
      to: purchase.user.email,
      subject: "Confirmación de tu pedido #{purchase.purchase_number} — QVITAL"
    )
  end

  # Notificación interna al admin de que se hizo un pedido nuevo.
  # Contenido propio (no es una copia del email del cliente): sin saludo
  # personalizado ni descargo médico, con los datos del cliente al frente
  # para que sea accionable de un vistazo.
  def admin_notification(purchase)
    @purchase = purchase
    @order = purchase.order
    items = purchase.purchase_items.includes(:product).to_a
    physical = items.reject { |item| item.product.digital? }
    @digital_only = physical.empty?
    @product_lines = physical.map { |item| herbalife_line(item) }

    address = purchase.shipping_address || {}
    @recipient_phone = purchase.recipient_phone.presence || address["phone"]
    @address_lines = address_lines(address)

    payment = purchase.payments.approved.order(:updated_at).last
    @payment_id = payment&.provider_payment_id.presence
    @paid_at = payment&.updated_at&.in_time_zone("America/Bogota")&.strftime("%d/%m/%Y %H:%M")
    @admin_url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:3010")}/admin/orders/#{@order&.id}"

    subject = "Nuevo pedido #{purchase.purchase_number} — QVITAL"
    subject += " (Plan Premium, sin envío)" if @digital_only

    mail(to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "admin@qvital.com"), subject: subject)
  end

  # Aviso al cliente de que su pedido ya salió. Solo lista productos físicos.
  def shipped(order)
    purchase = order.purchase
    @order = order
    @purchase = purchase
    @name = purchase.recipient_name.presence || purchase.user.name
    @product_lines = purchase.purchase_items.includes(:product).reject { |i| i.product.digital? }
                             .map { |i| "#{i.product.name} x#{i.quantity}" }
    tracking = order.tracking_info || {}
    @carrier = tracking["carrier"].presence
    @tracking_number = tracking["tracking_number"].presence
    @tracking_url = tracking["tracking_url"].presence
    @has_tracking = @carrier || @tracking_number
    @order_url = "#{ENV.fetch("FRONTEND_URL", "http://localhost:3010")}/marketplace/orders/#{order.id}"

    mail(to: purchase.user.email, subject: "¡Tu pedido #{purchase.purchase_number} va en camino!")
  end

  # Alerta interna: Wompi aprobó un cobro que no coincide con la compra
  # (monto o moneda). El pago queda sin aprobar hasta revisarlo a mano.
  def payment_alert(payment, reason)
    @payment = payment
    @purchase = payment.purchase
    @reason = reason

    mail(
      to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "admin@qvital.com"),
      subject: "⚠️ Revisar pago #{payment.provider_payment_id} — QVITAL"
    )
  end

  private

  # "<sku> · <nombre> · <sabor> · x<cantidad>", omitiendo sku y sabor vacíos.
  def herbalife_line(item)
    product = item.product
    [ product.sku.presence, product.name, product.flavor.presence, "x#{item.quantity}" ].compact.join(" · ")
  end

  def address_lines(address)
    city_state = [ address["city"], address["state"] ].map(&:presence).compact.join(", ")
    zip = address["zipCode"].presence && "Código postal: #{address["zipCode"]}"
    [ address["street"], address["addressDetails"], address["locality"], city_state, zip ].map(&:presence).compact
  end
end
