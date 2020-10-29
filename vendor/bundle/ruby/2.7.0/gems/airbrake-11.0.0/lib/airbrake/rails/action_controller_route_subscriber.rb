# frozen_string_literal: true

require 'airbrake/rails/event'
require 'airbrake/rails/app'

module Airbrake
  module Rails
    # ActionControllerRouteSubscriber sends route stat information, including
    # performance data.
    #
    # @since v8.0.0
    class ActionControllerRouteSubscriber
      def call(*args)
        return unless Airbrake::Config.instance.performance_stats

        # We don't track routeless events.
        return unless (routes = Airbrake::Rack::RequestStore[:routes])

        event = Airbrake::Rails::Event.new(*args)
        route = Airbrake::Rails::App.recognize_route(
          Airbrake::Rack::RequestStore[:request],
        )
        return unless route

        routes[route.path] = {
          method: event.method,
          response_type: event.response_type,
          groups: {},
        }
      end
    end
  end
end
