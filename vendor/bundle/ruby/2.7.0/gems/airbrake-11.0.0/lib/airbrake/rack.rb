# frozen_string_literal: true

require 'airbrake/rack/user'
require 'airbrake/rack/user_filter'
require 'airbrake/rack/context_filter'
require 'airbrake/rack/session_filter'
require 'airbrake/rack/http_params_filter'
require 'airbrake/rack/http_headers_filter'
require 'airbrake/rack/request_body_filter'
require 'airbrake/rack/route_filter'
require 'airbrake/rack/middleware'
require 'airbrake/rack/request_store'
require 'airbrake/rack/instrumentable'

module Airbrake
  # Rack is a namespace for all Rack-related code.
  module Rack
    # @since v9.2.0
    # @api public
    def self.capture_timing(label)
      return yield unless Airbrake::Config.instance.performance_stats

      routes = Airbrake::Rack::RequestStore[:routes]
      if !routes || routes.none?
        result = yield
      else
        timed_trace = Airbrake::TimedTrace.span(label) do
          result = yield
        end

        routes.each do |_route_path, params|
          params[:groups].merge!(timed_trace.spans)
        end
      end

      result
    end
  end
end
