# frozen_string_literal: true

module Doorkeeper
  module Rails
    class Routes
      # Thread-safe registry of any Doorkeeper additional routes.
      # Used to allow implementing of Doorkeeper extensions that must
      # use their own routes.
      #
      module Registry
        ROUTES_ACCESS_LOCK = Mutex.new
        ROUTES_DEFINITION_LOCK = Mutex.new

        InvalidRouterClass = Class.new(StandardError)

        # Collection of additional registered routes for Doorkeeper.
        #
        # @return [Array<Object>] set of registered routes
        #
        def registered_routes
          ROUTES_DEFINITION_LOCK.synchronize do
            @registered_routes ||= Set.new
          end
        end

        # Registers additional routes in the Doorkeeper registry
        #
        # @param [Object] routes
        #   routes class
        #
        def register_routes(routes)
          if !routes.is_a?(Module) || !(routes < AbstractRouter)
            raise InvalidRouterClass, "routes class must include Doorkeeper::Rails::AbstractRouter"
          end

          ROUTES_ACCESS_LOCK.synchronize do
            registered_routes << routes
          end
        end

        alias register register_routes
      end
    end
  end
end
