class RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      raw_token = @user.generate_email_verification_token!
      deliver_email_verification(@user, raw_token)
      redirect_to new_email_verification_path(email: @user.email),
        notice: "Account created! Please check your CUHK email to verify your account before signing in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: [ :email, :password, :password_confirmation, :cuhk_id, :username, :college_affiliation ])
  end

  def deliver_email_verification(user, raw_token)
    log_email_delivery_attempt(user)
    UserMailer.email_verification(user, raw_token).deliver_now
    log_email_delivery_success(user)
  rescue => err
    log_email_delivery_failure(err, user)
    Rails.logger.error("MAIL ERROR: #{err.class}: #{err.message}")
  end

  def log_email_delivery_attempt(user)
    # #region agent log
    DebugAgent9fbde1.log(
      hypothesis_id: "H1",
      location: "RegistrationsController#deliver_email_verification",
      message: "deliver_now_attempt",
      data: {
        delivery_method: ActionMailer::Base.delivery_method.to_s,
        smtp_address: ActionMailer::Base.smtp_settings&.dig(:address),
        smtp_port: ActionMailer::Base.smtp_settings&.dig(:port),
        smtp_username_present: ENV["SMTP_USERNAME"].present?,
        recipient_domain: user.email.to_s.split("@").last
      }
    )
    # #endregion
  end

  def log_email_delivery_success(user)
    # #region agent log
    DebugAgent9fbde1.log(
      hypothesis_id: "H1",
      location: "RegistrationsController#deliver_email_verification",
      message: "deliver_now_no_exception",
      data: { recipient_domain: user.email.to_s.split("@").last }
    )
    # #endregion
  end

  def log_email_delivery_failure(err, user)
    # #region agent log
    DebugAgent9fbde1.log(
      hypothesis_id: "H1-H2",
      location: "RegistrationsController#deliver_email_verification",
      message: "deliver_now_exception",
      data: {
        error_class: err.class.to_s,
        error_msg: err.message.to_s[0..400],
        recipient_domain: user.email.to_s.split("@").last
      }
    )
    # #endregion
  end
end
