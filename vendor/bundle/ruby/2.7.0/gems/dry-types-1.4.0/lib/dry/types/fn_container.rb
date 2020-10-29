# frozen_string_literal: true

require 'dry/types/container'

module Dry
  module Types
    # Internal container for constructor functions used by the built-in types
    #
    # @api private
    class FnContainer
      # @api private
      def self.container
        @container ||= Container.new
      end

      # @api private
      def self.register(function = Dry::Core::Constants::Undefined, &block)
        fn = Dry::Core::Constants::Undefined.default(function, block)
        fn_name = register_name(fn)
        container.register(fn_name, fn) unless container.key?(fn_name)
        fn_name
      end

      # @api private
      def self.[](fn_name)
        if container.key?(fn_name)
          container[fn_name]
        else
          fn_name
        end
      end

      # @api private
      def self.register_name(function)
        "fn_#{function.object_id}"
      end
    end
  end
end
