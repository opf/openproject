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
      # @yieldparam [Array] The strategies currently used by this scope. May be empty.
      # @yieldreturn [Array] The strategies to be used by this scope.
      def update_strategies(scope, store: nil, &block)
        raise ArgumentError, "invalid scope: #{scope}" unless Scope.values.include? scope

        current_strategies = Array(Manager.scope_strategies[scope])

        Manager.store_defaults[scope] = store unless store.nil?
        Manager.scope_strategies[scope] = block.call current_strategies if block_given?
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
  end
end
