# frozen_string_literal: true

# Feature-area smoke coverage map (see test/integration/*_flow_test.rb):
# - sessions, registrations
# - profiles, passwords
# - products, likes, sellers
# - conversations, messages, notifications
# - orders, stripe_account, stripe_webhooks
module IntegrationAuthHelpers
  FIXTURE_PASSWORD = "password123"

  def sign_in_as(user)
    post sign_in_path, params: { email: user.email, password: FIXTURE_PASSWORD }
    assert_response :redirect, "sign-in should redirect for #{user.email}"
  end
end
