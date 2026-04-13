# frozen_string_literal: true

require "test_helper"

class RegistrationsFlowTest < ActionDispatch::IntegrationTest
  test "sign up page loads" do
    get sign_up_path
    assert_response :success
  end

  test "rejects non-CUHK email" do
    assert_no_difference -> { User.count } do
      post sign_up_path, params: {
        user: {
          email: "a@gmail.com",
          password: "secret12",
          password_confirmation: "secret12",
          cuhk_id: "1155990009",
          username: "badmail",
          college_affiliation: "Shaw College"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "valid sign up creates user and redirects to email verification" do
    suffix = SecureRandom.hex(4)
    assert_difference -> { User.count }, +1 do
      post sign_up_path, params: {
        user: {
          email: "new#{suffix}@link.cuhk.edu.hk",
          password: "secret12",
          password_confirmation: "secret12",
          cuhk_id: "1155#{suffix}",
          username: "user#{suffix}",
          college_affiliation: "Shaw College"
        }
      }
    end
    assert_redirected_to new_email_verification_path(email: "new#{suffix}@link.cuhk.edu.hk")
  end
end
