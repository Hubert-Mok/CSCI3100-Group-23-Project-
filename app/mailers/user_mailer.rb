class UserMailer < ApplicationMailer
  DEBUG_LOG_PATH = Rails.root.join(".cursor", "debug-90ad6c.log")

  def email_verification(user, raw_token)
    @user = user
    @verification_url = email_verification_url(token: raw_token)
    @expiry_minutes = (User::EMAIL_VERIFICATION_EXPIRY / 1.minute).to_i

    mail(to: @user.email, subject: "Verify your CUHK Marketplace email")
  end

  def password_reset(user, raw_token)
    @user = user
    @reset_url = edit_password_reset_url(token: raw_token)
    @expiry_minutes = (User::PASSWORD_RESET_EXPIRY / 1.minute).to_i
    run_id = SecureRandom.hex(6)

    # #region agent log
    begin
      host = @reset_url.to_s.split("/")[2]
      File.open(DEBUG_LOG_PATH, "a") do |f|
        f.puts({
          sessionId: "90ad6c",
          runId: run_id,
          hypothesisId: "H4",
          location: "app/mailers/user_mailer.rb:password_reset",
          message: "Password reset email composed",
          data: { user_id: @user.id, reset_url_host: host, expiry_minutes: @expiry_minutes },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
      end
    rescue StandardError
    end
    # #endregion

    mail(to: @user.email, subject: "Reset your CUHK Marketplace password")
  end
end
