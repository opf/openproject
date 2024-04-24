module OpenProject
  class Inflector < Zeitwerk::GemInflector
    alias_method :default_inflect, :camelize

    def camelize(basename, abspath)
      self.class.camelize_rules.each do |rule|
        name = instance_exec(basename, abspath, &rule)

        return name if name
      end

      super
    end

    private

    def overrides
      self.class.inflections.merge(super)
    end

    class << self
      def rule(&block)
        camelize_rules << block
      end

      def camelize_rules
        @camelize_rules ||= []
      end

      def inflections
        @inflections ||= {}
      end

      def inflection(overrides)
        inflections.merge!(overrides)
      end
    end
  end
end
