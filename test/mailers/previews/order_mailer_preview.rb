# Previews disponibles en http://localhost:3011/rails/mailers (con el
# servidor corriendo en development). No envían nada — solo renderizan.
# Ver también CLAUDE.md § "Testing Mailers Locally".
class OrderMailerPreview < ActionMailer::Preview
  # http://localhost:3011/rails/mailers/order_mailer/confirmation
  # http://localhost:3011/rails/mailers/order_mailer/confirmation?purchase_number=PUR-XXXX
  def confirmation
    OrderMailer.confirmation(sample_purchase)
  end

  # http://localhost:3011/rails/mailers/order_mailer/admin_notification
  # http://localhost:3011/rails/mailers/order_mailer/admin_notification?purchase_number=PUR-XXXX
  def admin_notification
    OrderMailer.admin_notification(sample_purchase)
  end

  private

  # Sin `purchase_number`, usa la última compra con items (comportamiento
  # previo). Pasando `?purchase_number=PUR-XXXX` en la URL, fija una compra
  # concreta — útil para ver los dos correos de la MISMA orden lado a lado,
  # sin depender de qué sea "la última" en cada momento.
  def sample_purchase
    scope = Purchase.joins(:purchase_items).where.not(user_id: nil)
    scope = scope.where(purchase_number: params[:purchase_number]) if params[:purchase_number].present?
    scope.last
  end
end
