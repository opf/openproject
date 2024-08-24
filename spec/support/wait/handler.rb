# frozen_string_literal: true

# borrowed from rspec-wait, avoiding usage of Timeout
module RSpec
  module Wait
    module Handler
      def handle_matcher(target, *, &)
        t = Time.current

        begin
          actual = target.respond_to?(:call) ? target.call : target
          super(actual, *, &)
        rescue RSpec::Expectations::ExpectationNotMetError => e
          elapsed = Time.current - t
          if elapsed < RSpec.configuration.wait_timeout
            sleep RSpec.configuration.wait_delay
            retry
          else
            raise e
          end
        end
      end
    end

    # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/handler.rb#L46-L71
    class PositiveHandler < RSpec::Expectations::PositiveExpectationHandler
      extend Handler
    end

    # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/handler.rb#L74-L107
    class NegativeHandler < RSpec::Expectations::NegativeExpectationHandler
      extend Handler
    end
  end
end
