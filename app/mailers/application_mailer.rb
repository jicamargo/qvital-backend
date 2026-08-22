class ApplicationMailer < ActionMailer::Base
  default from: -> { "QVITAL <#{ENV.fetch('MAILER_FROM_EMAIL', 'pedidos@qvital.com')}>" }
  layout "mailer"
end
