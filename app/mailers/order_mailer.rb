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
    @items = purchase.purchase_items.includes(:product)

    mail(
      to: ENV.fetch("ADMIN_NOTIFICATION_EMAIL", "admin@qvital.com"),
      subject: "Nuevo pedido #{purchase.purchase_number} — QVITAL"
    )
  end
end
