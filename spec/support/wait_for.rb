# frozen_string_literal: true

require_relative "wait/handler"
require_relative "wait/target"

# borrowed from rspec-wait, avoiding usage of Timeout
module RSpec
  module Wait
    module_function

    # Drop-in replacement for `expect` assertions, waiting for the assertion to
    # pass.
    #
    # Useful for testing user interfaces with tricky timing elements like
    # JavaScript interactions or remote requests.
    #
    # The assertion is checked every `RSpec.configuration.wait_delay` seconds
    # until `RSpec.configuration.wait_timeout` seconds have passed.
    #
    # Default value of `wait_timeout` is 3. It can be overriden with `:timeout`
    # keyword parameter.
    #
    # Default value of `wait_delay` is 0.05. It can be overriden with `:delay`
    # keyword parameter.
    #
    # Examples:
    #   wait_for(ticker.tape).to eq("··-·")
    #   wait_for { ticker.tape }.to eq("··-· ---")
    def wait_for(value = Target::UndefinedValue, &block)
      Target.for(value, block)
    end

    # Sets timeout and delay values for `wait_for`.
    #
    # @param timeout [Numeric] time in seconds to wait up for assertions to pass
    # @param delay [Numeric] time in seconds elapsing between two checks of an
    #   assertion
    # Examples:
    # with_wait(timeout: 10, delay: 1) do
    #   wait_for { ticker.tape }.to eq("··-· ---")
    # end
    def with_wait(timeout: nil, delay: nil)
      original_timeout = RSpec.configuration.wait_timeout
      original_delay = RSpec.configuration.wait_delay

      RSpec.configuration.wait_timeout = timeout if timeout
      RSpec.configuration.wait_delay = delay if delay

      yield
    ensure
      RSpec.configuration.wait_timeout = original_timeout
      RSpec.configuration.wait_delay = original_delay
    end
  end
end

RSpec.configure do |config|
  config.include(RSpec::Wait)

  config.add_setting(:wait_timeout, default: 3)
  config.add_setting(:wait_delay, default: 0.05)
end
