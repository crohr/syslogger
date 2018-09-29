require 'simplecov'
require 'rspec'
require 'active_job'

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

# Module helper for unit tests
module JobBuffer
  class << self
    def clear
      values.clear
    end

    def add(value)
      values << value
    end

    def values
      @values ||= []
    end

    def last_value
      values.last
    end
  end
end

# Class helper for unit tests
class HelloJob < ActiveJob::Base
  def perform(greeter = "David")
    JobBuffer.add("#{greeter} says hello")
  end
end

# Configure I18n otherwise it throws errors in syslog
I18n.available_locales = [:en]

# Load lib
require 'syslogger'
