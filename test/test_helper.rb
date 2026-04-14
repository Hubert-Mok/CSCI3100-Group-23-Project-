require 'simplecov'
SimpleCov.command_name ENV.fetch('SIMPLECOV_COMMAND_NAME', 'Minitest')
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
end

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |f| require f }

class ActionDispatch::IntegrationTest
  include StripeTestHelpers
  include IntegrationAuthHelpers

  # allow_browser :modern blocks requests without a current browser user agent.
  MODERN_CHROME_UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36".freeze

  %i[get post patch put delete head].each do |verb|
    define_method(verb) do |path, **args|
      headers = (args[:headers] || {}).dup
      headers["User-Agent"] ||= MODERN_CHROME_UA
      args[:headers] = headers
      super(path, **args)
    end
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
