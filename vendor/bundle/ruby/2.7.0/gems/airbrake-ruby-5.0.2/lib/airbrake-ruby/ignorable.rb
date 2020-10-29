module Airbrake
  # Ignorable contains methods that allow the includee to be ignored.
  #
  # @example
  #   class A
  #     include Airbrake::Ignorable
  #   end
  #
  #   a = A.new
  #   a.ignore!
  #   a.ignored? #=> true
  #
  # @since v3.2.0
  # @api private
  module Ignorable
    attr_accessor :ignored

    # Checks whether the instance was ignored.
    # @return [Boolean]
    # @see #ignore!
    # rubocop:disable Style/DoubleNegation
    def ignored?
      !!ignored
    end
    # rubocop:enable Style/DoubleNegation

    # Ignores an instance. Ignored instances must never reach the Airbrake
    # dashboard.
    # @return [void]
    # @see #ignored?
    def ignore!
      self.ignored = true
    end

    private

    # A method that is meant to be used as a guard.
    # @raise [Airbrake::Error] when instance is ignored
    def raise_if_ignored
      return unless ignored?

      raise Airbrake::Error, "cannot access ignored #{self.class}"
    end
  end
end
