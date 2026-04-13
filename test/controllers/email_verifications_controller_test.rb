require "test_helper"

class EmailVerificationsControllerTest < ActionDispatch::IntegrationTest
  # GET /email_verification/new
  test "new renders check-email page" do
    get new_email_verification_path
    assert_response :success
  end

  # GET /email_verification?token=...
  test "show with valid token verifies email and redirects to sign in" do
    user = users(:unverified_user)
    raw_token = user.generate_email_verification_token!

    get email_verification_path(token: raw_token)
    assert_redirected_to sign_in_path
    assert_match "verified", flash[:notice]
    assert user.reload.email_verified?
  end

  test "show with invalid token redirects with alert" do
    get email_verification_path(token: "completely_invalid_token")
    assert_redirected_to sign_in_path
    assert_match "invalid", flash[:alert]
  end

  test "show with expired token redirects to resend page and enqueues new email" do
    user = users(:unverified_user)
    raw_token = user.generate_email_verification_token!
    user.update_columns(email_verification_sent_at: 2.hours.ago)

    assert_enqueued_emails 1 do
      get email_verification_path(token: raw_token)
    end

    assert_redirected_to new_email_verification_path(email: user.email)
    assert_match "expired", flash[:alert]
  end

  test "show redirects already-verified user to sign in" do
    user = users(:verified_user)
    raw_token = user.generate_email_verification_token!

    get email_verification_path(token: raw_token)
    assert_redirected_to sign_in_path
    assert_match "already verified", flash[:notice]
  end

  # POST /email_verification (resend)
  test "create sends new verification email for unverified user" do
    user = users(:unverified_user)

    assert_enqueued_emails 1 do
      post email_verification_path, params: { email: user.email }
    end

    assert_redirected_to new_email_verification_path(email: user.email)
  end

  test "create shows generic message for unknown email" do
    post email_verification_path, params: { email: "nobody@link.cuhk.edu.hk" }
    assert_redirected_to new_email_verification_path
  end

  test "create shows generic message for already-verified email" do
    user = users(:verified_user)
    post email_verification_path, params: { email: user.email }
    assert_redirected_to new_email_verification_path
  end
end
