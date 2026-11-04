# Diario: avisa por correo a las clientas cuyo Premium vence en los próximos
# WINDOW. `premium_reminder_sent_for` guarda el vencimiento ya avisado, así
# un mismo vencimiento se avisa una sola vez y uno renovado vuelve a avisarse.
class PremiumReminderJob < ApplicationJob
  queue_as :default

  WINDOW = 5.days

  def perform
    now = Time.current

    User.where(premium_active: true, premium_expires_at: now..(now + WINDOW))
        .where("premium_reminder_sent_for IS DISTINCT FROM premium_expires_at")
        .find_each do |user|
      send_reminder(user)
    end
  end

  private

  # Un fallo con una usuaria no frena a las demás; queda sin marcar y se
  # reintenta en la próxima corrida.
  def send_reminder(user)
    PremiumMailer.reminder(user).deliver_now
    user.update_columns(premium_reminder_sent_for: user.premium_expires_at)
  rescue StandardError => e
    Rails.logger.error("[PremiumReminderJob] user #{user.id}: #{e.class}: #{e.message}")
  end
end
