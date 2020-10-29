# frozen_string_literal: true

require 'airbrake/rails/app'

module Airbrake
  module Rack
    # Adds route slugs to context/route.
    # @since v7.5.0
    class RouteFilter
      attr_reader :weight

      def initialize
        @weight = 100
      end

      def call(notice)
        return unless (request = notice.stash[:rack_request])

        notice[:context][:route] =
          if action_dispatch_request?(request)
            rails_route(request)
          elsif sinatra_request?(request)
            sinatra_route(request)
          end
      end

      private

      def rails_route(request)
        return unless (route = Airbrake::Rails::App.recognize_route(request))

        route.path
      end

      def sinatra_route(request)
        return unless (route = request.env['sinatra.route'])

        route.split(' ').drop(1).join(' ')
      end

      def action_dispatch_request?(request)
        defined?(ActionDispatch::Request) &&
          request.instance_of?(ActionDispatch::Request)
      end

      def sinatra_request?(request)
        defined?(Sinatra::Request) && request.instance_of?(Sinatra::Request)
      end
    end
  end
end
