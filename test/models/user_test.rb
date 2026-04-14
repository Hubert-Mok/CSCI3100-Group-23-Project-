require "test_helper"

class UserTest < ActiveSupport::TestCase
  # --- school email domain validation ---

  test "allows link.cuhk.edu.hk email" do
    user = build_valid_user(email: "test@link.cuhk.edu.hk")
    assert user.valid?
  end

  test "allows cuhk.edu.hk email" do
    user = build_valid_user(email: "test@cuhk.edu.hk")
    assert user.valid?
  end

  test "rejects non-CUHK email domain" do
    user = build_valid_user(email: "test@gmail.com")
    assert_not user.valid?
    assert_includes user.errors[:email].to_sentence, "CUHK school email"
  end

  # --- email_verified? ---

  test "email_verified? returns true when email_verified_at is set" do
    assert users(:verified_user).email_verified?
  end

  test "email_verified? returns false when email_verified_at is nil" do
    assert_not users(:unverified_user).email_verified?
  end

  # --- email verification token lifecycle ---

  test "generate_email_verification_token! stores a digest and returns raw token" do
    user = users(:unverified_user)
    raw_token = user.generate_email_verification_token!
    user.reload

    assert_not_nil user.email_verification_token_digest
    assert_not_nil user.email_verification_sent_at
    assert raw_token.present?
  end

  test "email_verification_token_valid? returns true for correct token within expiry" do
    user = users(:unverified_user)
    raw_token = user.generate_email_verification_token!

    assert user.email_verification_token_valid?(raw_token)
  end

  test "email_verification_token_valid? returns false for wrong token" do
    user = users(:unverified_user)
    user.generate_email_verification_token!

    assert_not user.email_verification_token_valid?("wrong_token")
  end

  test "email_verification_token_valid? returns false for expired token" do
    user = users(:unverified_user)
    user.generate_email_verification_token!
    user.update_columns(email_verification_sent_at: 2.hours.ago)

    raw_digest_owner_token = SecureRandom.urlsafe_base64(32)
    user.update_columns(email_verification_token_digest: Digest::SHA256.hexdigest(raw_digest_owner_token))

    assert_not user.email_verification_token_valid?(raw_digest_owner_token)
  end

  test "verify_email! clears token fields and sets email_verified_at" do
    user = users(:unverified_user)
    user.generate_email_verification_token!
    user.verify_email!
    user.reload

    assert_not_nil user.email_verified_at
    assert_nil user.email_verification_token_digest
    assert_nil user.email_verification_sent_at
  end

  # --- password reset token lifecycle ---

  test "generate_password_reset_token! stores digest and returns raw token" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!
    user.reload

    assert_not_nil user.password_reset_token_digest
    assert_not_nil user.password_reset_sent_at
    assert raw_token.present?
  end

  test "password_reset_token_valid? returns true for correct token within expiry" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!

    assert user.password_reset_token_valid?(raw_token)
  end

  test "password_reset_token_valid? returns false for wrong token" do
    user = users(:verified_user)
    user.generate_password_reset_token!

    assert_not user.password_reset_token_valid?("bad_token")
  end

  test "password_reset_token_valid? returns false after expiry" do
    user = users(:verified_user)
    raw_token = user.generate_password_reset_token!
    user.update_columns(password_reset_sent_at: 1.hour.ago)

    assert_not user.password_reset_token_valid?(raw_token)
  end

  test "clear_password_reset_token! nullifies digest and sent_at" do
    user = users(:verified_user)
    user.generate_password_reset_token!
    user.clear_password_reset_token!
    user.reload

    assert_nil user.password_reset_token_digest
    assert_nil user.password_reset_sent_at
  end

  private

  def build_valid_user(overrides = {})
    User.new({
      email: "student@link.cuhk.edu.hk",
      password: "password123",
      password_confirmation: "password123",
      cuhk_id: SecureRandom.hex(5),
      username: "testuser",
      college_affiliation: "Shaw College"
    }.merge(overrides))
  end
end
