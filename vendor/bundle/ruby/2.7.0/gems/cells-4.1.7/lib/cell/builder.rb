require "declarative/builder"

module Cell
  module Builder
    def self.included(base)
      base.send :include, Declarative::Builder
      base.extend ClassMethods
    end

    module ClassMethods
      def build(*args)
        build!(self, *args).new(*args) # Declarative::Builder#build!.
      end
    end
  end
end
