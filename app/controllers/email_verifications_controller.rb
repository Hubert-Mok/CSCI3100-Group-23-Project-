class EmailVerificationsController < ApplicationController
  # GET /email_verification?token=...
  # Link clicked from the verification email.
  def show
    token = params[:token].to_s

    user = find_user_by_token(:email_verification_token_digest, token)

    if user.nil?
      redirect_to sign_in_path, alert: "Verification link is invalid."
      return
    end

    if user.email_verified?
      redirect_to sign_in_path, notice: "Your email is already verified. Please sign in."
      return
    end

    unless user.email_verification_token_valid?(token)
      redirect_to new_email_verification_path(email: user.email),
        alert: "Verification link has expired. A new one has been sent to your email."
      resend_for(user)
      return
    end

    user.verify_email!
    redirect_to sign_in_path, notice: "Email verified! You can now sign in."
  end

  # GET /email_verification/new?email=...
  # Page shown when user needs to resend or when they land on the check-email page.
  def new
    @email = params[:email].to_s
  end

  # POST /email_verification
  # Resend a verification email.
  def create
    email = params[:email].to_s.downcase
    user = User.find_by(email: email)

    if user.nil? || user.email_verified?
      # Always show the same message to avoid leaking whether an account exists.
      redirect_to new_email_verification_path, notice: "If that email is registered and unverified, we've sent a new verification link."
      return
    end

    resend_for(user)
    redirect_to new_email_verification_path(email: email),
      notice: "A new verification email has been sent. Please check your inbox."
  end

  private

  def find_user_by_token(digest_column, raw_token)
    digest = Digest::SHA256.hexdigest(raw_token)
    User.find_by(digest_column => digest)
  end

  def resend_for(user)
    raw_token = user.generate_email_verification_token!
    UserMailer.email_verification(user, raw_token).deliver_now
  end
end
