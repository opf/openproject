require 'open_project/authentication/manager'

module OpenProject
  ##
  # OpenProject uses Warden strategies for request authentication.
  module Authentication
    class << self
      ##
      # Updates the used warden strategies for a given scope. The strategies will be tried
      # in the order they are set here. Plugins can call this to add or remove strategies.
      # For available scopes please refer to `OpenProject::Authentication::Scope`.
      #
      # @param [Symbol] scope The scope for which to update the used warden strategies.
      # @param [Boolean] store Indicates whether the user should be stored in the session
      #                        for this scope. Optional. If not given, the current store flag
      #                        for this strategy will remain unchanged what ever it is.
      #
      # @yield [strategies] A block returning the strategies to be used for this scope.
      # @yieldparam [Array] strategies The strategies currently used by this scope. May be empty.
      # @yieldreturn [Array] The strategies to be used by this scope.
      def update_strategies(scope, store: nil, &block)
        raise ArgumentError, "invalid scope: #{scope}" unless Scope.values.include? scope

        current_strategies = Array(Manager.scope_strategies[scope])

        Manager.store_defaults[scope] = store unless store.nil?
        Manager.scope_strategies[scope] = block.call current_strategies if block_given?
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
    # General options used in the WWW-Authenticate header returned to the user
    # in case authentication failed (401).
    module WWWAuthenticate
      module_function

      ##
      # Per default the scheme is 'Basic' which is recognized by the browser
      # which will promt the user to provide basic auth credentials in order
      # to authenticate.
      #
      # When using the APIv3 through Angular, e.g. in the work package view,
      # this behaviour is not desired, however. If the user is not logged in
      # the calls should just fail.
      #
      # It is impossible to suppress the prompt using Javascript.
      # Hence we rename the auth scheme in a way that makes it still obvious
      # to developers that it is basic auth but still unknown to the browser
      # thereby avoiding the undesired prompt.
      def auth_scheme
        'BasicAuth'
      end

      def realm
        'OpenProject API'
      end
    end
  end
end

Warden::Strategies::BasicAuth.prepend OpenProject::Authentication::WWWAuthenticate
