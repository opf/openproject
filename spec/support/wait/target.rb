# frozen_string_literal: true

# borrowed from rspec-wait
module RSpec
  module Wait
    class Target < RSpec::Expectations::ExpectationTarget
      # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/expectation_target.rb#L22
      UndefinedValue = Module.new

      # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/expectation_target.rb#L31-L33
      def initialize(target, **options)
        @wait_options = options
        super(target)
      end

      # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/expectation_target.rb#L36-L47
      def self.for(value, block, **)
        if UndefinedValue.equal?(value)
          unless block
            raise ArgumentError, "You must pass either an argument or a block to `wait_for`."
          end

          new(block, **)
        elsif block
          raise ArgumentError, "You cannot pass both an argument and a block to `wait_for`."
        else
          new(value, **)
        end
      end

      # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/expectation_target.rb#L63-L66
      def to(matcher = nil, message = nil, &)
        prevent_operator_matchers(:to) unless matcher
        with_wait { PositiveHandler.handle_matcher(@target, matcher, message, &) }
      end

      # From: https://github.com/rspec/rspec-expectations/blob/v3.12.3/lib/rspec/expectations/expectation_target.rb#L76-L79
      def not_to(matcher = nil, message = nil, &)
        prevent_operator_matchers(:not_to) unless matcher
        with_wait { NegativeHandler.handle_matcher(@target, matcher, message, &) }
      end

      alias_method :to_not, :not_to

      private

      def with_wait(&)
        Wait.with_wait(**@wait_options, &)
      end
    end
  end
end
