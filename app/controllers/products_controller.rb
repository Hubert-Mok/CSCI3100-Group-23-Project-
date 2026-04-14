class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy delete_chats]
  before_action :require_login, only: %i[new create edit update destroy delete_chats]
  before_action :require_verified_email, only: %i[new create edit update destroy delete_chats]
  before_action :require_owner, only: %i[edit update destroy delete_chats]

  def index
    scope = logged_in? ? Product.where.not(user: current_user) : Product.all
    scope = scope.where(flagged: false)
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
      if @product.pending?
        flash[:warning] = "Listing created and pending admin approval."
      else
        flash[:notice] = "Listing published successfully!"
      end
      if @product.sale? && @product.available? && current_user.stripe_account_id.blank?
        flash[:alert] = "Connect your Stripe account so buyers can use Buy Now and you can receive payments."
      end
      redirect_to @product
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_status = @product.status
    if @product.update(product_params)
      if @product.status != old_status
        @product.broadcast_replace_to(
          @product,
          target: "product_status_#{@product.id}",
          partial: "products/status_badge",
          locals: { product: @product }
        )
        interested = (@product.likers + @product.conversations.map(&:buyer)).uniq - [ @product.user ]
        interested.each do |recipient|
          notif = Notification.create!(
            user: recipient,
            product: @product,
            message: "\"#{@product.title}\" is now #{@product.status.capitalize}"
          )
          Turbo::StreamsChannel.broadcast_prepend_to(
            "notifications:#{recipient.id}",
            target: "notifications_list",
            partial: "notifications/notification",
            locals: { notification: notif }
          )
          broadcast_notification_badge_to(recipient)
        end
      end
      if @product.sale? && @product.available? && current_user.stripe_account_id.blank?
        flash[:alert] = "Connect your Stripe account so buyers can use Buy Now and you can receive payments."
      end
      redirect_to @product, notice: "Listing updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      if current_user.admin? && request.referer&.include?("admin/moderation")
        redirect_to admin_moderation_index_path, notice: "Listing removed successfully."
      else
      redirect_to profile_path, notice: "Listing removed successfully."
      end
    else
      redirect_to @product, alert: "Listing could not be removed. Please try again."
    end
  end

  def delete_chats
    unless @product.sold?
      redirect_to profile_path, alert: "Chats can only be deleted after the listing is marked as sold."
      return
    end

    @product.conversations.destroy_all
    redirect_to profile_path, notice: "All chats for this listing have been deleted."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def require_owner
    unless current_user == @product.user || current_user.admin?
      redirect_to @product, alert: "You are not authorised to manage this listing."
    end
  end

  def product_params
    params.require(:product).permit(:title, :description, :price, :listing_type, :status, :category, :thumbnail)
  end
end
