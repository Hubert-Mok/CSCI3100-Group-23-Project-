class PasswordResetsController < ApplicationController
  # GET /password/forgot
  def new
  end

  # POST /password/forgot
  def create
    email = params[:email].to_s.downcase
    user = User.find_by(email: email)

    # Always show the same response to prevent user enumeration.
    if user&.email_verified?
      raw_token = user.generate_password_reset_token!
      UserMailer.password_reset(user, raw_token).deliver_later
    end

    redirect_to new_password_reset_path,
      notice: "If an account with that email exists, we've sent a password reset link. Please check your inbox."
  end

  # GET /password/reset?token=...
  def edit
    @token = params[:token].to_s
    @user = find_user_by_reset_token(@token)

    if @user.nil? || !@user.password_reset_token_valid?(@token)
      redirect_to new_password_reset_path, alert: "Password reset link is invalid or has expired. Please request a new one."
    end
  end

  # PATCH /password/reset
  def update
    @token = params[:token].to_s
    @user = find_user_by_reset_token(@token)

    if @user.nil? || !@user.password_reset_token_valid?(@token)
      redirect_to new_password_reset_path, alert: "Password reset link is invalid or has expired. Please request a new one."
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      @user.clear_password_reset_token!
      reset_session
      redirect_to sign_in_path, notice: "Password reset successfully. Please sign in with your new password."
    else
      flash.now[:alert] = @user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_user_by_reset_token(raw_token)
    return nil if raw_token.blank?

    digest = Digest::SHA256.hexdigest(raw_token)
    User.find_by(password_reset_token_digest: digest)
  end
end
