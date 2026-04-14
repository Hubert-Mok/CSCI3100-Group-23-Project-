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
    UserMailer.email_verification(user, raw_token).deliver_now
  rescue => err
    Rails.logger.error("MAIL ERROR: #{err.class}: #{err.message}")
  end
end
