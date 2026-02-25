class RegistrationsController < ApplicationController
  def new
    redirect_to root_path, notice: "You are already signed in." if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      reset_session
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created successfully. Welcome, #{@user.username}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.expect(user: [ :email, :password, :password_confirmation, :cuhk_id, :username, :college_affiliation ])
  end
end
