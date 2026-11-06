require "test_helper"
require "fugit"

class PremiumReminderJobTest < ActiveSupport::TestCase
  setup do
    @level = Level.find_or_create_by!(name: "Cliente") { |l| l.priority = 1 }
    ActionMailer::Base.deliveries.clear
  end

  def premium_user(expires_in:, active: true)
    User.create!(
      email: "reminder-#{SecureRandom.hex(4)}@example.com", role: "cliente", level: @level,
      premium_active: active, premium_expires_at: expires_in.from_now
    )
  end

  test "reminds a user expiring in 4 days and records the expiry" do
    user = premium_user(expires_in: 4.days)

    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      PremiumReminderJob.perform_now
    end
    assert_equal user.premium_expires_at, user.reload.premium_reminder_sent_for
  end

  test "ignores users expiring in 6 days" do
    premium_user(expires_in: 6.days)
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      PremiumReminderJob.perform_now
    end
  end

  test "ignores already expired users" do
    premium_user(expires_in: -1.day)
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      PremiumReminderJob.perform_now
    end
  end

  test "ignores inactive premium even when expiring in 3 days" do
    premium_user(expires_in: 3.days, active: false)
    assert_no_difference -> { ActionMailer::Base.deliveries.size } do
      PremiumReminderJob.perform_now
    end
  end

  test "running twice sends only one email" do
    premium_user(expires_in: 4.days)
    assert_difference -> { ActionMailer::Base.deliveries.size }, 1 do
      PremiumReminderJob.perform_now
      PremiumReminderJob.perform_now
    end
  end

  test "a renewed premium is reminded again when the new expiry approaches" do
    user = premium_user(expires_in: 4.days)
    PremiumReminderJob.perform_now
    assert_equal 1, ActionMailer::Base.deliveries.size

    user.update!(premium_expires_at: user.premium_expires_at + 30.days)
    PremiumReminderJob.perform_now
    assert_equal 1, ActionMailer::Base.deliveries.size

    travel_to 30.days.from_now do
      PremiumReminderJob.perform_now
    end
    assert_equal 2, ActionMailer::Base.deliveries.size
    assert_equal user.reload.premium_expires_at, user.premium_reminder_sent_for
  end

  test "a mailer failure for one user does not mark them nor stop the others" do
    failing = premium_user(expires_in: 3.days)
    ok = premium_user(expires_in: 4.days)

    original = PremiumMailer.method(:reminder)
    PremiumMailer.define_singleton_method(:reminder) do |user|
      raise "boom" if user.id == failing.id
      original.call(user)
    end

    begin
      PremiumReminderJob.perform_now
    ensure
      PremiumMailer.define_singleton_method(:reminder, original)
    end

    assert_nil failing.reload.premium_reminder_sent_for
    assert_equal ok.premium_expires_at, ok.reload.premium_reminder_sent_for
    assert_equal [ ok.email ], ActionMailer::Base.deliveries.flat_map(&:to)
  end

  test "recurring.yml schedules the job daily at 9am Bogota in production and development" do
    config = YAML.load_file(Rails.root.join("config/recurring.yml"))

    %w[production development].each do |env|
      entry = config.fetch(env).fetch("premium_reminder")
      assert_equal "PremiumReminderJob", entry["class"]

      cron = Fugit.parse(entry["schedule"])
      assert_kind_of Fugit::Cron, cron
      assert_equal [ 9 ], cron.hours
      assert_equal [ 0 ], cron.minutes
      assert_equal "America/Bogota", cron.timezone.name
    end
  end
end
