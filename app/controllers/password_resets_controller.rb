class PasswordResetsController < ApplicationController
  DEBUG_LOG_PATH = Rails.root.join(".cursor", "debug-90ad6c.log")

  # GET /password/forgot
  def new
  end

  # POST /password/forgot
  def create
    email = params[:email].to_s.downcase
    user = User.find_by(email: email)
    run_id = SecureRandom.hex(6)

    # #region agent log
    begin
      Rails.logger.info({
        sessionId: "90ad6c",
        runId: run_id,
        hypothesisId: "H1",
        location: "app/controllers/password_resets_controller.rb:create",
        message: "Password reset request received",
        data: { user_found: user.present?, email_verified: user&.email_verified? || false, user_id: user&.id, adapter: ActiveJob::Base.queue_adapter.class.name },
        timestamp: (Time.now.to_f * 1000).to_i
      }.to_json)
      File.open(DEBUG_LOG_PATH, "a") do |f|
        f.puts({
          sessionId: "90ad6c",
          runId: run_id,
          hypothesisId: "H1",
          location: "app/controllers/password_resets_controller.rb:create",
          message: "Password reset request received",
          data: { user_found: user.present?, email_verified: user&.email_verified? || false, user_id: user&.id, adapter: ActiveJob::Base.queue_adapter.class.name },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
      end
    rescue StandardError
    end
    # #endregion

    # Always show the same response to prevent user enumeration.
    if user&.email_verified?
      raw_token = user.generate_password_reset_token!
      # Password reset is latency-sensitive and must not depend on async worker availability.
      UserMailer.password_reset(user, raw_token).deliver_now
      # #region agent log
      begin
        Rails.logger.info({
          sessionId: "90ad6c",
          runId: run_id,
          hypothesisId: "H2",
          location: "app/controllers/password_resets_controller.rb:create",
          message: "Password reset mail delivered synchronously",
          data: { user_id: user.id },
          timestamp: (Time.now.to_f * 1000).to_i
        }.to_json)
        File.open(DEBUG_LOG_PATH, "a") do |f|
          f.puts({
            sessionId: "90ad6c",
            runId: run_id,
            hypothesisId: "H2",
            location: "app/controllers/password_resets_controller.rb:create",
            message: "Password reset mail delivered synchronously",
            data: { user_id: user.id },
            timestamp: (Time.now.to_f * 1000).to_i
          }.to_json)
        end
      rescue StandardError
      end
      # #endregion
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
