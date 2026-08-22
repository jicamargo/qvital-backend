# Previews disponibles en http://localhost:3001/rails/mailers (con el
# servidor corriendo en development). No envían nada — solo renderizan.
# Ver también CLAUDE.md § "Testing Mailers Locally".
class OrderMailerPreview < ActionMailer::Preview
  # http://localhost:3001/rails/mailers/order_mailer/confirmation
  def confirmation
    OrderMailer.confirmation(sample_purchase)
  end

  # http://localhost:3001/rails/mailers/order_mailer/admin_notification
  def admin_notification
    OrderMailer.admin_notification(sample_purchase)
  end

  private

  def sample_purchase
    Purchase.joins(:purchase_items).where.not(user_id: nil).last
  end
end
