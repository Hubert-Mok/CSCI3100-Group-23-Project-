# frozen_string_literal: true

require "test_helper"

class ProductsLikesSellersFlowTest < ActionDispatch::IntegrationTest
  def create_seller_with_product(stripe: true)
    suffix = SecureRandom.hex(3)
    seller = User.create!(
      email: "seller#{suffix}@link.cuhk.edu.hk",
      password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password_confirmation: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      cuhk_id: "1199#{suffix}",
      username: "seller#{suffix}",
      college_affiliation: "Shaw College",
      email_verified_at: Time.current,
      stripe_account_id: (stripe ? "acct_test_#{suffix}" : nil)
    )
    product = seller.products.create!(
      title: "Desk lamp for study",
      description: "Bright LED desk lamp, perfect for late-night revision sessions.",
      price: 120,
      category: "Furniture & Home",
      listing_type: :sale,
      status: :available
    )
    [ seller, product ]
  end

  test "guest can browse root and search" do
    get root_path
    assert_response :success
    get root_path, params: { q: "lamp", category: "Electronics", sort: "price_asc" }
    assert_response :success
  end

  test "verified user can create and update own listing" do
    user = users(:verified_user)
    sign_in_as user

    get new_product_path
    assert_response :success

    assert_difference -> { Product.count }, +1 do
      post products_path, params: {
        product: {
          title: "Used textbook bundle",
          description: "Several second-year textbooks in good condition, minimal highlighting.",
          price: 80,
          category: "Books & Notes",
          listing_type: "sale"
        }
      }
    end
    product = Product.order(:created_at).last
    assert_redirected_to product_path(product)
    follow_redirect!
    assert_response :success

    patch product_path(product), params: {
      product: {
        title: "Used textbook bundle (updated)",
        description: "Several second-year textbooks in good condition, minimal highlighting.",
        price: 75,
        category: "Books & Notes",
        listing_type: "sale",
        status: "available"
      }
    }
    assert_redirected_to product_path(product)
  end

  test "non-owner cannot edit listing" do
    seller, product = create_seller_with_product
    buyer = users(:verified_user)
    sign_in_as buyer

    get edit_product_path(product)
    assert_redirected_to product_path(product)
  end

  test "owner can destroy listing" do
    seller, product = create_seller_with_product
    sign_in_as seller

    assert_difference -> { Product.count }, -1 do
      delete product_path(product)
    end
    assert_redirected_to profile_path
  end

  test "guest cannot like; verified user can like and unlike" do
    _seller, product = create_seller_with_product
    post product_like_path(product)
    assert_redirected_to sign_in_path

    sign_in_as users(:verified_user)
    assert_difference -> { Like.count }, +1 do
      post product_like_path(product)
    end
    assert_redirected_to product_path(product)

    assert_difference -> { Like.count }, -1 do
      delete product_like_path(product)
    end
    assert_redirected_to product_path(product)
  end

  test "seller public profile shows available listings" do
    seller, _product = create_seller_with_product
    get seller_path(seller)
    assert_response :success
  end
end
