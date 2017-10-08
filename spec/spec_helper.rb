require 'simplecov'
require 'rspec'

# Start Simplecov
SimpleCov.start

# Configure RSpec
RSpec.configure do |config|
  config.color = true
  config.fail_fast = false

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Load lib
require 'syslogger'
