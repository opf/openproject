require 'representable'

module OpenProject::RepresentablePatch
  def self.included(base)
    base.class_eval do
      def self.as_strategy=(strategy)
        raise 'The :as_strategy option should respond to #call?' unless strategy.respond_to?(:call)

        @as_strategy = strategy
      end

      def self.as_strategy
        @as_strategy
      end

      def self.property(name, options = {}, &block)
        options = { as: as_strategy.call(name.to_s) }.merge(options) if as_strategy

        super
      end
    end
  end
end

unless Representable::Decorator.included_modules.include?(OpenProject::RepresentablePatch)
  Representable::Decorator.include(OpenProject::RepresentablePatch)
end
