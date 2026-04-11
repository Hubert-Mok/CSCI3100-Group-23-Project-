class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@cuhk-marketplace.com")
  layout "mailer"
end
