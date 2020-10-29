require "virtus"

module Representable
  module Coercion
    class Coercer
      def initialize(type)
        @type = type
      end

      # This gets called when the :render_filter or :parse_filter option is evaluated.
      # Usually the Coercer instance is an element in a Pipeline to allow >1 filters per property.
      def call(input, options)
        Virtus::Attribute.build(@type).coerce(input)
      end
    end


    def self.included(base)
      base.class_eval do
        extend ClassMethods
        register_feature Coercion
      end
    end


    module ClassMethods
      def property(name, options={}, &block)
        super.tap do |definition|
          return definition unless type = options[:type]

          definition.merge!(render_filter: coercer = Coercer.new(type))
          definition.merge!(parse_filter: coercer)
        end
      end
    end
  end
end