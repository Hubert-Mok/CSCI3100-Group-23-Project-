class SellersController < ApplicationController
  def show
    @seller = User.find(params[:id])
    @products = @seller.products.available
                         .includes(thumbnail_attachment: :blob)
                         .order(created_at: :desc)
  end
end
