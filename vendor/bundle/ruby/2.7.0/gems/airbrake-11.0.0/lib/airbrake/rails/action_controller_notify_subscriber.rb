# frozen_string_literal: true

require 'airbrake/rails/event'

module Airbrake
  module Rails
    # ActionControllerNotifySubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerNotifySubscriber
      def call(*args)
        return unless Airbrake::Config.instance.performance_stats

        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)

        routes.each do |route, _params|
          Airbrake.notify_request(
            method: event.method,
            route: route,
            status_code: event.status_code,
            timing: event.duration,
            time: event.time,
          )
        end
      end
    end
  end
end
