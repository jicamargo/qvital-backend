# http://localhost:3011/rails/mailers/premium_mailer/reminder
# Sin `?email=`, usa la última usuaria con Premium; si no hay, la última usuaria.
class PremiumMailerPreview < ActionMailer::Preview
  def reminder
    user = User.find_by(email: params[:email]) if params[:email].present?
    user ||= User.where.not(premium_expires_at: nil).order(:premium_expires_at).last || User.last
    user.premium_expires_at ||= 3.days.from_now
    PremiumMailer.reminder(user)
  end
end
