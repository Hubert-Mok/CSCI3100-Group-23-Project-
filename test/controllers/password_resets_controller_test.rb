require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  # GET /password/forgot
  test "new renders forgot password form" do
    get new_password_reset_path
    assert_response :success
  end

  # POST /password/forgot
  test "create sends reset email for verified account and shows generic notice" do
    user = users(:verified_user)

    assert_enqueued_emails 1 do
      post password_reset_request_path, params: { email: user.email }
    end

    assert_redirected_to new_password_reset_path
    assert_match "check your inbox", flash[:notice].downcase
  end

  test "create shows same generic notice for unknown email (anti-enumeration)" do
    assert_enqueued_emails 0 do
      post password_reset_request_path, params: { email: "ghost@link.cuhk.edu.hk" }
    end

    assert_redirected_to new_password_reset_path
    assert_match "check your inbox", flash[:notice].downcase
  end

  test "create does not send reset email for unverified account" do
    user = users(:unverified_user)

    assert_enqueued_emails 0 do
      post password_reset_request_path, params: { email: user.email }
    end
  end

  # GET /password/reset?token=...
  test "edit with valid token renders reset form" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!

    get edit_password_reset_path(token: raw_token)
    assert_response :success
  end

  test "edit with invalid token redirects with alert" do
    get edit_password_reset_path(token: "bad_token")
    assert_redirected_to new_password_reset_path
    assert flash[:alert].present?
  end

  test "edit with expired token redirects with alert" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!
    user.update_columns(password_reset_sent_at: 1.hour.ago)

    get edit_password_reset_path(token: raw_token)
    assert_redirected_to new_password_reset_path
    assert flash[:alert].present?
  end

  # PATCH /password/reset
  test "update with valid token resets password and redirects to sign in" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!
    old_digest = user.password_digest

    patch password_reset_path, params: {
      token: raw_token,
      password: "newpassword1",
      password_confirmation: "newpassword1"
    }

    assert_redirected_to sign_in_path
    assert_match "reset successfully", flash[:notice]
    assert_not_equal old_digest, user.reload.password_digest
    assert_nil user.reload.password_reset_token_digest
  end

  test "update rejects mismatched passwords" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!

    patch password_reset_path, params: {
      token: raw_token,
      password: "newpassword1",
      password_confirmation: "differentpassword"
    }

    assert_response :unprocessable_entity
    assert flash[:alert].present?
  end

  test "update with expired token redirects" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!
    user.update_columns(password_reset_sent_at: 1.hour.ago)

    patch password_reset_path, params: {
      token: raw_token,
      password: "newpassword1",
      password_confirmation: "newpassword1"
    }

    assert_redirected_to new_password_reset_path
    assert flash[:alert].present?
  end
end
