class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new]

  def new; end

  def create
    user = find_user_by_email

    if user&.authenticate(params[:password])
      return redirect_to_email_verification(user) unless user.email_verified?

      sign_in(user)
    else
      render_invalid_credentials
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end

  private

  def find_user_by_email
    User.find_by(email: params[:email].to_s.downcase)
  end

  def redirect_to_email_verification(user)
    redirect_to new_email_verification_path(email: user.email),
      alert: "Please verify your email before signing in. Check your inbox or request a new link below."
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
    redirect_to root_path, notice: "Signed in successfully. Welcome, #{user.username}!"
  end

  def render_invalid_credentials
    flash.now[:alert] = "Invalid email or password."
    render :new, status: :unprocessable_entity
  end
end
