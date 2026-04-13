# frozen_string_literal: true

require "test_helper"

class SessionsFlowTest < ActionDispatch::IntegrationTest
  test "invalid sign in renders form" do
    post sign_in_path, params: { email: "nope@link.cuhk.edu.hk", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "verified user can sign in and sign out" do
    user = users(:verified_user)
    post sign_in_path, params: { email: user.email, password: IntegrationAuthHelpers::FIXTURE_PASSWORD }
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success

    delete sign_out_path
    assert_redirected_to root_path
  end

  test "unverified user cannot sign in" do
    user = users(:unverified_user)
    post sign_in_path, params: { email: user.email, password: IntegrationAuthHelpers::FIXTURE_PASSWORD }
    assert_redirected_to %r{/email_verification/new}
  end
end
