require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "email_verification mail is addressed correctly and contains the token link" do
    user = users(:unverified_user)
    raw_token = user.generate_email_verification_token!

    mail = UserMailer.email_verification(user, raw_token)

    assert_equal [user.email], mail.to
    assert_match "Verify", mail.subject
    assert_match raw_token, mail.body.encoded
  end

  test "password_reset mail is addressed correctly and contains the token link" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!

    mail = UserMailer.password_reset(user, raw_token)

    assert_equal [user.email], mail.to
    assert_match "Reset", mail.subject
    assert_match raw_token, mail.body.encoded
  end
end
