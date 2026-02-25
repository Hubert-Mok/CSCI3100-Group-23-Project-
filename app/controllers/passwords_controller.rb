class PasswordsController < ApplicationController
  before_action :require_login

  def edit
  end

  def update
    unless current_user.authenticate(params[:current_password].to_s)
      flash.now[:alert] = "Current password is incorrect."
      return render :edit, status: :unprocessable_entity
    end

    if current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      redirect_to profile_path, notice: "Password updated successfully."
    else
      flash.now[:alert] = current_user.errors.full_messages.to_sentence
      render :edit, status: :unprocessable_entity
    end
  end
end
