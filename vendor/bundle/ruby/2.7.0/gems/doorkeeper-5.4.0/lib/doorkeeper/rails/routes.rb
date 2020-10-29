# frozen_string_literal: true

require "doorkeeper/rails/routes/mapping"
require "doorkeeper/rails/routes/mapper"
require "doorkeeper/rails/routes/abstract_router"
require "doorkeeper/rails/routes/registry"

module Doorkeeper
  module Rails
    class Routes # :nodoc:
      module Helper
        def use_doorkeeper(options = {}, &block)
          Doorkeeper::Rails::Routes.new(self, &block).generate_routes!(options)
        end
      end

      include AbstractRouter
      extend Registry

      mattr_reader :mapping do
        {}
      end

      def self.install!
        ActionDispatch::Routing::Mapper.include Doorkeeper::Rails::Routes::Helper

        registered_routes.each(&:install!)
      end

      def initialize(routes, mapper = Mapper.new, &block)
        super

        @mapping.skips.push(:applications, :authorized_applications) if Doorkeeper.config.api_only
      end

      def generate_routes!(options)
        routes.scope options[:scope] || "oauth", as: "oauth" do
          map_route(:authorizations, :authorization_routes)
          map_route(:tokens, :token_routes)
          map_route(:tokens, :revoke_routes)
          map_route(:tokens, :introspect_routes)
          map_route(:applications, :application_routes)
          map_route(:authorized_applications, :authorized_applications_routes)
          map_route(:token_info, :token_info_routes)
        end
      end

      private

      def authorization_routes(mapping)
        routes.resource(
          :authorization,
          path: "authorize",
          only: %i[create destroy],
          as: mapping[:as],
          controller: mapping[:controllers],
        ) do
          routes.get "/native", action: :show, on: :member
          routes.get "/", action: :new, on: :member
        end
      end

      def token_routes(mapping)
        routes.resource(
          :token,
          path: "token",
          only: [:create], as: mapping[:as],
          controller: mapping[:controllers],
        )
      end

      def revoke_routes(mapping)
        routes.post "revoke", controller: mapping[:controllers], action: :revoke
      end

      def introspect_routes(mapping)
        routes.post "introspect", controller: mapping[:controllers], action: :introspect
      end

      def token_info_routes(mapping)
        routes.resource(
          :token_info,
          path: "token/info",
          only: [:show], as: mapping[:as],
          controller: mapping[:controllers],
        )
      end

      def application_routes(mapping)
        routes.resources :doorkeeper_applications,
                         controller: mapping[:controllers],
                         as: :applications,
                         path: "applications"
      end

      def authorized_applications_routes(mapping)
        routes.resources :authorized_applications,
                         only: %i[index destroy],
                         controller: mapping[:controllers]
      end
    end
  end
end
