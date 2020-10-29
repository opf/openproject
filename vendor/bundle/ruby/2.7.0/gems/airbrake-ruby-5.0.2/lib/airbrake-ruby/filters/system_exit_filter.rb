module Airbrake
  module Filters
    # Skip over SystemExit exceptions, because they're just noise.
    # @api private
    class SystemExitFilter
      # @return [String]
      SYSTEM_EXIT_TYPE = 'SystemExit'.freeze

      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 130
      end

      # @macro call_filter
      def call(notice)
        return if notice[:errors].none? { |error| error[:type] == SYSTEM_EXIT_TYPE }

        notice.ignore!
      end
    end
  end
end
