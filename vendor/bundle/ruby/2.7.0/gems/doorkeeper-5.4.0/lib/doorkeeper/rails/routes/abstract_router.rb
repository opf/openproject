# frozen_string_literal: true

module Doorkeeper
  module Rails
    # Abstract router module that implements base behavior
    # for generating and mapping Rails routes.
    #
    # Could be reused in Doorkeeper extensions.
    #
    module AbstractRouter
      extend ActiveSupport::Concern

      attr_reader :routes

      def initialize(routes, mapper = Mapper.new, &block)
        @routes = routes
        @mapping = mapper.map(&block)
      end

      def generate_routes!(**_options)
        raise NotImplementedError, "must be redefined for #{self.class.name}!"
      end

      private

      def map_route(name, method)
        return if @mapping.skipped?(name)

        send(method, @mapping[name])

        mapping[name] = @mapping[name]
      end
    end
  end
end
