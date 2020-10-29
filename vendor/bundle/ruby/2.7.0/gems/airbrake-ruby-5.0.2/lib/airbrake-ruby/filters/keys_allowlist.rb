module Airbrake
  module Filters
    # A default Airbrake notice filter. Filters everything in the payload of a
    # notice, but specified keys.
    #
    # @example
    #   filter = Airbrake::Filters::KeysAllowlist.new(
    #     [:email, /credit/i, 'password']
    #   )
    #   airbrake.add_filter(filter)
    #   airbrake.notify(StandardError.new('App crashed!'), {
    #     user: 'John',
    #     password: 's3kr3t',
    #     email: 'john@example.com',
    #     account_id: 42
    #   })
    #
    #   # The dashboard will display this parameters as filtered, but other
    #   # values won't be affected:
    #   #   { user: 'John',
    #   #     password: '[Filtered]',
    #   #     email: 'john@example.com',
    #   #     account_id: 42 }
    #
    # @see KeysBlocklist
    # @see KeysFilter
    class KeysAllowlist
      include KeysFilter

      def initialize(*)
        super
        @weight = -100
      end

      # @return [Boolean] true if the key doesn't match any pattern, false
      #   otherwise.
      def should_filter?(key)
        @patterns.none? do |pattern|
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
