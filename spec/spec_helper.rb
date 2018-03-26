require 'bundler/setup'
require 'simplecov'
require 'simplecov-console'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.mock_with :rspec

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

SimpleCov.formatters = [
  SimpleCov::Formatter::Console
]
SimpleCov.start do
  add_group 'Library', 'lib'
  add_group 'Specs', 'spec'
end

require 'container-notify'
