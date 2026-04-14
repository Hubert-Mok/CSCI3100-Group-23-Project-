class UserMailer < ApplicationMailer
  DEBUG_LOG_PATH = Rails.root.join(".cursor", "debug-0c3e21.log")

  def email_verification(user, raw_token)
    @user = user
    @verification_url = email_verification_url(token: raw_token)
    @expiry_minutes = (User::EMAIL_VERIFICATION_EXPIRY / 1.minute).to_i

    mail(to: @user.email, subject: "Verify your CUHK Marketplace email")
  end

  def password_reset(user, raw_token)
    run_id = SecureRandom.hex(6)
    # #region agent log
    begin
      File.open(DEBUG_LOG_PATH, "a") do |f|
        f.puts({
          sessionId: "0c3e21",
          runId: run_id,
          hypothesisId: "H3",
          location: "app/mailers/user_mailer.rb:password_reset",
          message: "Password reset mailer method invoked",
          data: { user_id: user.id },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
      end
    rescue StandardError
    end
    # #endregion

    @user = user
    @reset_url = edit_password_reset_url(token: raw_token)
    @expiry_minutes = (User::PASSWORD_RESET_EXPIRY / 1.minute).to_i
    reset_host = begin
      URI.parse(@reset_url).host
    rescue StandardError
      nil
    end

    # #region agent log
    begin
      File.open(DEBUG_LOG_PATH, "a") do |f|
        f.puts({
          sessionId: "0c3e21",
          runId: run_id,
          hypothesisId: "H4",
          location: "app/mailers/user_mailer.rb:password_reset",
          message: "Password reset mail object being built",
          data: { reset_url_present: @reset_url.present?, host: reset_host },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
      end
    rescue StandardError
    end
    # #endregion

    mail(to: @user.email, subject: "Reset your CUHK Marketplace password")
  end
end
