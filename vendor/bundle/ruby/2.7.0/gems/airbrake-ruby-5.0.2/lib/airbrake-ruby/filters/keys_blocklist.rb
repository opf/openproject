module Airbrake
  module Filters
    # A default Airbrake notice filter. Filters only specific keys listed in the
    # list of parameters in the payload of a notice.
    #
    # @example
    #   filter = Airbrake::Filters::KeysBlocklist.new(
    #     [:email, /credit/i, 'password']
    #   )
    #   airbrake.add_filter(filter)
    #   airbrake.notify(StandardError.new('App crashed!'), {
    #     user: 'John'
    #     password: 's3kr3t',
    #     email: 'john@example.com',
    #     credit_card: '5555555555554444'
    #   })
    #
    #   # The dashboard will display this parameter as is, but all other
    #   # values will be filtered:
    #   #   { user: 'John',
    #   #     password: '[Filtered]',
    #   #     email: '[Filtered]',
    #   #     credit_card: '[Filtered]' }
    #
    # @see KeysAllowlist
    # @see KeysFilter
    # @api private
    class KeysBlocklist
      include KeysFilter

      def initialize(*)
        super
        @weight = -110
      end

      # @return [Boolean] true if the key matches at least one pattern, false
      #   otherwise
      def should_filter?(key)
        @patterns.any? do |pattern|
          if pattern.is_a?(Regexp)
            key.match(pattern)
          else
            key.to_s == pattern.to_s
          end
        end
      end
    end
  end
end
