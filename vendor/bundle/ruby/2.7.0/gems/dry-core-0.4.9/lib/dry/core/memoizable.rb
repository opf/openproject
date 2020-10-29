# frozen_string_literal: true

module Dry
  module Core
    module Memoizable
      MEMOIZED_HASH = {}.freeze

      module ClassInterface
        def memoize(*names)
          prepend(Memoizer.new(self, names))
        end

        def new(*)
          obj = super
          obj.instance_variable_set(:'@__memoized__', MEMOIZED_HASH.dup)
          obj
        end
      end

      def self.included(klass)
        super
        klass.extend(ClassInterface)
      end

      attr_reader :__memoized__

      # @api private
      class Memoizer < Module
        attr_reader :klass
        attr_reader :names

        # @api private
        def initialize(klass, names)
          @names = names
          @klass = klass
          define_memoizable_names!
        end

        private

        # @api private
        def define_memoizable_names!
          names.each do |name|
            meth = klass.instance_method(name)

            if meth.parameters.size > 0
              define_method(name) do |*args|
                name_with_args = :"#{name}_#{args.hash}"

                if __memoized__.key?(name_with_args)
                  __memoized__[name_with_args]
                else
                  __memoized__[name_with_args] = super(*args)
                end
              end
            else
              define_method(name) do
                if __memoized__.key?(name)
                  __memoized__[name]
                else
                  __memoized__[name] = super()
                end
              end
            end
          end
        end
      end
    end
  end
end
