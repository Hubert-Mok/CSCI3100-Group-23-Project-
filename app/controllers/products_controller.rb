class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :require_login, only: %i[new create edit update destroy]
  before_action :require_owner, only: %i[edit update destroy]

  def index
    scope = logged_in? ? Product.where.not(user: current_user) : Product.all
    scope = scope.search(params[:q])
                 .by_category(params[:category])
                 .by_status(params[:status])
    @products = scope.includes(:user, thumbnail_attachment: :blob)
                     .sorted_by(params[:sort])
    @liked_ids = logged_in? ? current_user.likes.pluck(:product_id) : []
  end

  def show
    @liked = logged_in? && current_user.likes.exists?(product: @product)
  end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)

    if @product.save
      redirect_to @product, notice: "Listing published successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Listing updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      redirect_to profile_path, notice: "Listing removed successfully."
    else
      redirect_to @product, alert: "Listing could not be removed. Please try again."
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def require_owner
    unless current_user == @product.user
      redirect_to @product, alert: "You are not authorised to manage this listing."
    end
  end

  def product_params
    params.expect(product: [ :title, :description, :price, :listing_type, :status, :category, :thumbnail ])
  end
end
