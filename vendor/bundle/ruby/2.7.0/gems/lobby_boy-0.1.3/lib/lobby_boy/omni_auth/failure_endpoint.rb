module LobbyBoy
  module OmniAuth
    # This is a copy of the default OmniAuth FailureEndpoint
    # minus the raise_out! we don't want and plus the actual error message
    # as opposed to always just 'missing_code'.
    #
    # Also when authentication with prompt=none fails it will retry with prompt=login.
    class FailureEndpoint
      attr_reader :env

      def self.call(env)
        new(env).call
      end

      def initialize(env)
        @env = env
      end

      def call
        if script?
          redirect_to '/session/state?state=unauthenticated'
        elsif retry?
          retry_interactive
        else
          redirect_to_failure
        end
      end

      def params
        request.params
      end

      def request
        @request ||= ::Rack::Request.new env
      end

      def error
        env['omniauth.error'] || ::OmniAuth::Error.new(env['omniauth.error.type'])
      end

      def script?
        origin =~ /#{script_name}\/session\/state/
      end

      ##
      # Authentication with &prompt=none fails if the user is not already signed in
      # with the respective provider. Retry without &prompt=none in that case.
      #
      # Google responds with 'immediate_failed' in that case.
      # Our own concierge with 'interaction_required'.
      def retry?
        ['immediate_failed', 'interaction_required'].include? error.message
      end

      def retry_interactive
        url = "#{omniauth_path}/#{strategy.name}?#{origin_query_param}&prompt=login"

        redirect_to url
      end

      def redirect_to_failure
        params = [
          message_query_param(error.message),
          origin_query_param,
          strategy_name_query_param
        ]

        url = omniauth_path + '/failure?' + params.compact.join('&')

        redirect_to url
      end

      def omniauth_path
        script_name + ::OmniAuth.config.path_prefix
      end

      def script_name
        env['SCRIPT_NAME']
      end

      def message_query_param(message)
        'message=' + escape(message)
      end

      def strategy_name_query_param
        'strategy=' + escape(strategy.name) if strategy
      end

      def strategy
        env['omniauth.error.strategy']
      end

      def origin
        env['omniauth.origin']
      end

      def origin_query_param
        'origin=' + escape(origin) if origin
      end

      module Functions
        module_function

        def redirect_to(url)
          Rack::Response.new(['302 Moved'], 302, 'Location' => url.to_s).finish
        end

        def escape(string)
          Rack::Utils.escape(string)
        end
      end

      include Functions
    end
  end
end
