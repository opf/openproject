# frozen_string_literal: true

module Airbrake
  module Rails
    # Event is a wrapper around ActiveSupport::Notifications::Event.
    #
    # @since v9.0.3
    # @api private
    class Event
      # @see https://github.com/rails/rails/issues/8987
      HTML_RESPONSE_WILDCARD = "*/*"

      include Airbrake::Loggable

      def initialize(*args)
        @event = ActiveSupport::Notifications::Event.new(*args)
      end

      def method
        @event.payload[:method]
      end

      def response_type
        response_type = @event.payload[:format]
        response_type == HTML_RESPONSE_WILDCARD ? :html : response_type
      end

      def params
        @event.payload[:params]
      end

      def sql
        @event.payload[:sql]
      end

      def db_runtime
        @db_runtime ||= @event.payload[:db_runtime] || 0
      end

      def view_runtime
        @view_runtime ||= @event.payload[:view_runtime] || 0
      end

      def time
        @event.time
      end

      def groups
        groups = {}
        groups[:db] = db_runtime if db_runtime > 0
        groups[:view] = view_runtime if view_runtime > 0
        groups
      end

      def status_code
        return @event.payload[:status] if @event.payload[:status]

        if @event.payload[:exception]
          status = ActionDispatch::ExceptionWrapper.status_code_for_exception(
            @event.payload[:exception].first,
          )
          status = 500 if status == 0

          return status
        end

        # The ActiveSupport event doesn't have status only in two cases:
        #   - an exception was thrown
        #   - unauthorized access
        # We have already handled the exception so what's left is unauthorized
        # access. There's no way to know for sure it's unauthorized access, so
        # we are rather optimistic here.
        401
      end

      def duration
        @event.duration
      end
    end
  end
end
