class SessionsController < ApplicationController
  def new
    redirect_to root_path, notice: "You are already signed in." if logged_in?
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user&.authenticate(params[:password])
      unless user.email_verified?
        redirect_to new_email_verification_path(email: user.email),
          alert: "Please verify your email before signing in. Check your inbox or request a new link below."
        return
      end

      reset_session
      session[:user_id] = user.id
      redirect_to root_path, notice: "Signed in successfully. Welcome, #{user.username}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out successfully."
  end
end
