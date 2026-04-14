class UserMailer < ApplicationMailer
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

    mail(to: @user.email, subject: "Reset your CUHK Marketplace password")
  end
end
