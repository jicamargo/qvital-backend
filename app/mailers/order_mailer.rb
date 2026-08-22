class OrderMailer < ApplicationMailer
  # Confirmación de pedido al cliente, con copia oculta al admin.
  # Ver docs/requirements/fase3-personalizacion-objetivos-salud.md §5.2.
  def confirmation(purchase)
    @purchase = purchase
    @order = purchase.order
    @items = purchase.purchase_items.includes(:product)

    mail(
      to: purchase.user.email,
      bcc: admin_notification_email,
      subject: "Confirmación de tu pedido #{purchase.purchase_number} — QVITAL"
    )
  end

  private

  def admin_notification_email
    ENV["ADMIN_NOTIFICATION_EMAIL"].presence
  end
end
