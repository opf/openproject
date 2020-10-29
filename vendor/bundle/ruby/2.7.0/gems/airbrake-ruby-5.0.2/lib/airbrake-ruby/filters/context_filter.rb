module Airbrake
  module Filters
    # Adds user context to the notice object. Clears the context after it's
    # attached.
    #
    # @api private
    # @since v2.9.0
    class ContextFilter
      # @return [Integer]
      attr_reader :weight

      def initialize(context)
        @context = context
        @weight = 119
        @mutex = Mutex.new
      end

      # @macro call_filter
      def call(notice)
        @mutex.synchronize do
          return if @context.empty?

          notice[:params][:airbrake_context] = @context.dup
          @context.clear
        end
      end
    end
  end
end
