class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update]
  before_action :require_login, only: %i[new create edit update]
  before_action :require_owner, only: %i[edit update]

  def index
    scope = logged_in? ? Product.where.not(user: current_user) : Product.all
    @products = scope.includes(:user, thumbnail_attachment: :blob).latest
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

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def require_owner
    unless current_user == @product.user
      redirect_to @product, alert: "You are not authorised to edit this listing."
    end
  end

  def product_params
    params.expect(product: [ :title, :description, :price, :listing_type, :status, :category, :thumbnail ])
  end
end
