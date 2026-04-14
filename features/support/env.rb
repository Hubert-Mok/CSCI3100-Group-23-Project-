# Cucumber environment setup
ENV['RAILS_ENV'] = 'test'

require 'capybara'
require 'capybara/dsl'

# Load Rails environment
rails_root = File.join(File.dirname(__FILE__), '..', '..')
require File.join(rails_root, 'config', 'environment')

# Configure Capybara
Capybara.app = Rails.application
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :rack_test
Capybara.default_host = 'http://127.0.0.1'
Capybara.app_host = 'http://127.0.0.1'
Rails.application.config.hosts << '127.0.0.1'
Rails.application.config.hosts << 'www.example.com'

# Stripe mocking helpers
FakeCheckoutSession = Struct.new(:id, :url, :payment_status, :payment_intent)
FakeTransfer = Struct.new(:id)

def mock_stripe_for_cucumber
  # Mock Stripe::Checkout::Session.create
  Stripe::Checkout::Session.define_singleton_method(:create) do |**kwargs|
    FakeCheckoutSession.new('cs_test_session', 'https://checkout.stripe.com/test', 'unpaid', nil)
  end

  # Mock Stripe::Checkout::Session.retrieve
  Stripe::Checkout::Session.define_singleton_method(:retrieve) do |session_id|
    FakeCheckoutSession.new(session_id, 'https://checkout.stripe.com/test', 'paid', 'pi_test')
  end

  # Mock Stripe::Transfer.create
  Stripe::Transfer.define_singleton_method(:create) do |**kwargs|
    FakeTransfer.new('tr_test_transfer')
  end
end

# Set up Stripe mocking at startup
mock_stripe_for_cucumber

# Database cleaning
Before do |scenario|
  # Clean database between scenarios
  # Delete dependent records first (respecting foreign key constraints)
  Message.delete_all
  Conversation.delete_all
  Notification.delete_all
  Order.delete_all
  Like.delete_all
  Product.delete_all
  User.delete_all
end

# World mixins
World(Capybara::DSL)
World(Rails.application.routes.url_helpers)
World(ActionDispatch::Integration::Runner)
