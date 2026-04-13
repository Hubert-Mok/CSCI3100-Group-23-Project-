require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/test/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
end

at_exit { SimpleCov.result.format! }

ENV['RAILS_ENV'] ||= 'test'

require 'bundler/setup'
require 'rspec'

RSpec.configure do |config|
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
