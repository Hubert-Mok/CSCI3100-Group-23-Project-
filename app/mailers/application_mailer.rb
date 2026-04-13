class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "cuhkmarketplace@gmail.com")
  layout "mailer"
end
