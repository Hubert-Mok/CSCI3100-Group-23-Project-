class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @products = current_user.products.latest
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.expect(user: [ :username, :email, :college_affiliation ])
  end
end
