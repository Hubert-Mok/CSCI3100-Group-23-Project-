# frozen_string_literal: true

require "test_helper"

class ProfilesPasswordsFlowTest < ActionDispatch::IntegrationTest
  test "profile and password pages require login" do
    get profile_path
    assert_redirected_to sign_in_path

    get edit_profile_path
    assert_redirected_to sign_in_path

    get edit_password_path
    assert_redirected_to sign_in_path
  end

  test "verified user can view profile and update username" do
    user = users(:verified_user)
    sign_in_as user

    get profile_path
    assert_response :success

    patch profile_path, params: { user: { username: "alice_updated", email: user.email, college_affiliation: user.college_affiliation } }
    assert_redirected_to profile_path
    assert_equal "alice_updated", user.reload.username
  end

  test "password update fails with wrong current password" do
    user = users(:verified_user)
    sign_in_as user

    patch password_path, params: {
      current_password: "wrongpassword",
      password: "newpass12",
      password_confirmation: "newpass12"
    }
    assert_response :unprocessable_entity
  end

  test "password update succeeds with correct current password" do
    user = users(:verified_user)
    sign_in_as user

    patch password_path, params: {
      current_password: IntegrationAuthHelpers::FIXTURE_PASSWORD,
      password: "newpass12",
      password_confirmation: "newpass12"
    }
    assert_redirected_to profile_path
    assert user.reload.authenticate("newpass12")
  end
end
