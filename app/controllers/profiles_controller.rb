class ProfilesController < ApplicationController
  before_action :require_login

  def show
    @products = current_user.products.latest
    @liked_products = current_user.liked_products.includes(:user).latest
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      if only_theme_preference_update?
        redirect_back fallback_location: profile_path, notice: "Theme updated."
      else
        redirect_to profile_path, notice: "Profile updated successfully."
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.expect(user: [ :username, :email, :college_affiliation, :avatar, :theme_preference ])
  end

  def only_theme_preference_update?
    user_params = params[:user]
    return false unless user_params.respond_to?(:keys)

    user_params.keys.map(&:to_s) == ["theme_preference"]
  end
end
