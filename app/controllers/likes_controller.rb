class LikesController < ApplicationController
  before_action :require_login
  before_action :set_product

  def create
    if @product.user_id == current_user.id
      redirect_to @product, alert: "You cannot like your own listing."
      return
    end

    like = current_user.likes.create(product: @product)
    if like.persisted?
      redirect_to @product, notice: "Added to your liked items."
    else
      redirect_to @product, alert: "Could not like this item."
    end
  end

  def destroy
    like = current_user.likes.find_by(product: @product)
    if like&.destroy
      redirect_to @product, notice: "Removed from your liked items."
    else
      redirect_to @product, alert: "Could not unlike this item."
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end
end
