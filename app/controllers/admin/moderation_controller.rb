class Admin::ModerationController < ApplicationController
  before_action :require_admin # Ensure you have an admin check!

  def index
    @flagged_products = Product.flagged_for_review.order(created_at: :desc)
    @flagged_messages = Message.where(flagged: true).order(created_at: :desc)
  end

  def approve_product
    @product = Product.find(params[:id])
    if @product.update(flagged: false, status: :available)
        redirect_to admin_moderation_path, notice: "Product approved and listed!"
    else
        redirect_to admin_moderation_path, alert: "Failed to approve."
    end
  end

  private

  def require_admin
    # Basic check: adjust this based on how you identify admins
    redirect_to root_path, alert: "Access denied." unless current_user.admin?
  end
end