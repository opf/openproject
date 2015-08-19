require 'open_project/authentication/manager'

module OpenProject
  ##
  # OpenProject uses Warden strategies for request authentication.
  module Authentication
    class << self
      ##
      # Registers a given Warden strategy to be used for authentication.
      #
      # @param [Symbol] Name under which the strategy can be referred to.
      # @param [Class] The strategy class.
      # @param [String] The authentication scheme implemented by this strategy.
      #                 Used in the WWW-Authenticate header in 401 responses.
      def add_strategy(name, clazz, auth_scheme)
        Warden::Strategies.add name, clazz

        info = Manager.auth_scheme auth_scheme
        info.strategies << name
      end

      ##
      # Updates the used warden strategies for a given scope. The strategies will be tried
      # in the order they are set here. Plugins can call this to add or remove strategies.
      # For available scopes please refer to `OpenProject::Authentication::Scope`.
      #
      # @param [Symbol] scope The scope for which to update the used warden strategies.
      # @param [Hash] opts Options for that scope.
      # @option opts [Boolean] :store Indicates whether the user should be stored in the session
      #                               for this scope. Optional. If not given, the current store
      #                               flag for this strategy will remain unchanged what ever it is.
      # @option opts [String] :realm The WWW-Authenticate realm used for authentication challenges
      #                              for this scope. The default value ()
      #
      # @yield [strategies] A block returning the strategies to be used for this scope.
      # @yieldparam [Set] strategies The strategies currently used by this scope. May be empty.
      # @yieldreturn [Set] The strategies to be used by this scope.
      def update_strategies(scope, opts = {}, &block)
        raise ArgumentError, "invalid scope: #{scope}" unless Scope.values.include? scope

        config = Manager.scope_config scope
        config.update! opts, &block
      end

      ##
      # Allows to handle an authentication failure with a custom response.
      #
      # @param [Symbol] scope The scope for which to set the custom failure handler. Optional.
      #                       If omitted the default failure handler is set.
      #
      # @yield [failure_handler] A block returning a custom failure response.
      # @yieldparam [Warden::Proxy] warden Warden instance giving access to the would-be
      #                             result message and headers.
      # @yieldparam [Hash] warden_options Warden options including the scope of the failed
      #                                   strategy and the attempted request path.
      # @yieldreturn [Array] A rack standard response such as `[401, {}, ['unauthenticated']]`.
      def handle_failure(scope: nil, &block)
        Manager.failure_handlers[scope] = block
      end
    end

    ##
    # This module is only there to declare all used scopes. Technically a scope can be an
    # arbitrary symbol. But we declare them here not to lose sight of them.
    #
    # Plugins can declare new scopes by declaring new constants in this module.
    module Scope
      API_V3 = :api_v3

      class << self
        def values
          constants.map do |name|
            const_get name
          end
        end
      end
    end

    ##
    # Options used in the WWW-Authenticate header returned to the user
    # in case authentication failed (401).
    module WWWAuthenticate
      module_function

      def pick_auth_scheme(supported_schemes, default_scheme, request_headers = {})
        req_scheme = request_headers['HTTP_X_AUTHENTICATION_SCHEME']

        if supported_schemes.include? req_scheme
          req_scheme
        else
          default_scheme
        end
      end

      def default_auth_scheme
        'Basic'
      end

      def default_realm
        'OpenProject API'
      end

      def scope_realm(scope = nil)
        Manager.scope_config(scope).realm || default_realm
      end

      def response_header(
        default_auth_scheme: self.default_auth_scheme,
        scope: nil,
        request_headers: {}
      )
        scheme = pick_auth_scheme auth_schemes(scope), default_auth_scheme, request_headers

        "#{scheme} realm=\"#{scope_realm(scope)}\""
      end

      def auth_schemes(scope)
        strategies = Array(Manager.scope_config(scope).strategies)

        Manager.auth_schemes
          .select { |_, info| scope.nil? or not (info.strategies & strategies).empty? }
          .keys
      end
    end

    module AuthHeaders
      include WWWAuthenticate

      # #scope available from Warden::Strategies::BasicAuth

      def auth_scheme
        pick_auth_scheme auth_schemes(scope), default_auth_scheme, env
      end

      def realm
        scope_realm scope
      end
    end
  end
end

Warden::Strategies::BasicAuth.prepend OpenProject::Authentication::AuthHeaders
