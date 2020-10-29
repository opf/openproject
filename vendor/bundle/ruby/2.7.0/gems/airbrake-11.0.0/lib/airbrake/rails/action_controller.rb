# frozen_string_literal: true

module Airbrake
  module Rails
    # Contains helper methods that can be used inside Rails controllers to send
    # notices to Airbrake. The main benefit of using them instead of the direct
    # API is that they automatically add information from the Rack environment
    # to notices.
    module ActionController
      private

      # A helper method for sending notices to Airbrake *asynchronously*.
      # Attaches information from the Rack env.
      # @see Airbrake#notify, #notify_airbrake_sync
      def notify_airbrake(exception, params = {}, &block)
        return unless (notice = build_notice(exception, params))

        Airbrake.notify(notice, params, &block)
      end

      # A helper method for sending notices to Airbrake *synchronously*.
      # Attaches information from the Rack env.
      # @see Airbrake#notify_sync, #notify_airbrake
      def notify_airbrake_sync(exception, params = {}, &block)
        return unless (notice = build_notice(exception, params))

        Airbrake.notify_sync(notice, params, &block)
      end

      # @param [Exception] exception
      # @return [Airbrake::Notice] the notice with information from the Rack env
      def build_notice(exception, params = {})
        return unless (notice = Airbrake.build_notice(exception, params))

        notice.stash[:rack_request] = request
        notice
      end
    end
  end
end
