# frozen_string_literal: true

require 'airbrake/rails/event'

module Airbrake
  module Rails
    # @since v8.3.0
    class ActionControllerPerformanceBreakdownSubscriber
      def call(*args)
        return unless Airbrake::Config.instance.performance_stats

        routes = Airbrake::Rack::RequestStore[:routes]
        return if !routes || routes.none?

        event = Airbrake::Rails::Event.new(*args)
        stash = build_stash

        routes.each do |route, params|
          groups = event.groups.merge(params[:groups])
          next if groups.none?

          breakdown_info = {
            method: event.method,
            route: route,
            response_type: event.response_type,
            groups: groups,
            timing: event.duration,
            time: event.time,
          }

          Airbrake.notify_performance_breakdown(breakdown_info, stash)
        end
      end

      private

      def build_stash
        stash = {}
        request = Airbrake::Rack::RequestStore[:request]
        return stash unless request

        stash[:request] = request
        if (user = Airbrake::Rack::User.extract(request.env))
          stash.merge!(user.as_json)
        end

        stash
      end
    end
  end
end
