require 'simplecov'
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

# #region agent log
begin
  integration_paths = Dir[Rails.root.join("test/integration/**/*_test.rb")].sort
  payload = {
    sessionId: "4e5ee3",
    hypothesisId: "H-discovery",
    location: "test/test_helper.rb",
    message: "minitest file discovery",
    data: {
      integration_count: integration_paths.size,
      integration_basenames: integration_paths.map { |p| File.basename(p) },
      ci: ENV["CI"].present?,
      pid: $$
    },
    timestamp: (Time.now.to_f * 1000).to_i
  }
  log_path = Rails.root.join(".cursor/debug-4e5ee3.log")
  log_path.dirname.mkpath
  File.open(log_path, "a") { |f| f.puts(payload.to_json) }
  $stdout.puts("AGENT_DEBUG_DISCOVERY #{payload.to_json}") if ENV["CI"].present?
rescue StandardError => e
  warn("AGENT_DEBUG_DISCOVERY_LOG_FAIL #{e.class}: #{e.message}")
end
# #endregion
