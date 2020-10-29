# frozen_string_literal: true

module Airbrake
  module Rack
    # Adds context (URL, User-Agent, framework version, controller and more).
    #
    # @since v5.7.0
    class ContextFilter
      # @return [Integer]
      attr_reader :weight

      def initialize
        @weight = 99
      end

      # @see Airbrake::FilterChain#refine
      def call(notice)
        return unless (request = notice.stash[:rack_request])

        context = notice[:context]

        context[:url] = request.url
        context[:userAddr] =
          if request.respond_to?(:remote_ip)
            request.remote_ip
          else
            request.ip
          end
        context[:userAgent] = request.user_agent

        add_framework_version(context)

        controller = request.env['action_controller.instance']
        return unless controller

        context[:component] = controller.controller_name
        context[:action] = controller.action_name
      end

      private

      def add_framework_version(context)
        if context.key?(:versions)
          context[:versions].merge!(framework_version)
        else
          context[:versions] = framework_version
        end
      end

      def framework_version
        @framework_version ||=
          if defined?(::Rails) && ::Rails.respond_to?(:version)
            { 'rails' => ::Rails.version }
          elsif defined?(::Sinatra)
            { 'sinatra' => Sinatra::VERSION }
          else
            {
              'rack_version' => ::Rack.version,
              'rack_release' => ::Rack.release,
            }
          end
      end
    end
  end
end
