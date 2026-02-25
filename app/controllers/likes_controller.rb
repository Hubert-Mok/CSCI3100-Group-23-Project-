class LikesController < ApplicationController
  before_action :require_login
  before_action :set_product

  def create
    current_user.likes.create(product: @product)
    redirect_to @product
  end

  def destroy
    like = current_user.likes.find_by(product: @product)
    like&.destroy
    redirect_to @product
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
