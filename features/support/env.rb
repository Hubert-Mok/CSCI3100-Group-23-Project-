# Cucumber environment setup
ENV['RAILS_ENV'] = 'test'

require 'capybara'
require 'capybara/dsl'
require 'rspec/mocks'

# Load Rails environment
rails_root = File.join(File.dirname(__FILE__), '..', '..')
require File.join(rails_root, 'config', 'environment')

# Include RSpec mocks
include RSpec::Mocks::ExampleMethods

# Configure Capybara
Capybara.app = Rails.application
Capybara.default_driver = :rack_test
Capybara.javascript_driver = :rack_test
Capybara.default_host = 'http://127.0.0.1'
Capybara.app_host = 'http://127.0.0.1'
Rails.application.config.hosts << '127.0.0.1'
Rails.application.config.hosts << 'www.example.com'

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
World(RSpec::Mocks::ExampleMethods)
