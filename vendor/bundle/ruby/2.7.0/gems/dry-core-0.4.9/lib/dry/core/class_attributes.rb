# frozen_string_literal: true

require 'dry/core/constants'
require 'dry/core/errors'

module Dry
  module Core
    # Internal support module for class-level settings
    #
    # @api public
    module ClassAttributes
      include Constants

      # Specify what attributes a class will use
      #
      # @example
      #  class ExtraClass
      #    extend Dry::Core::ClassAttributes
      #
      #    defines :hello
      #
      #    hello 'world'
      #  end
      #
      # @example with inheritance and type checking
      #
      #  class MyClass
      #    extend Dry::Core::ClassAttributes
      #
      #    defines :one, :two, type: Integer
      #
      #    one 1
      #    two 2
      #  end
      #
      #  class OtherClass < MyClass
      #    two 3
      #  end
      #
      #  MyClass.one # => 1
      #  MyClass.two # => 2
      #
      #  OtherClass.one # => 1
      #  OtherClass.two # => 3
      #
      # @example with dry-types
      #
      #  class Foo
      #    extend Dry::Core::ClassAttributes
      #
      #    defines :one, :two, type: Dry::Types['strict.int']
      #  end
      #
      def defines(*args, type: Object)
        mod = Module.new do
          args.each do |name|
            define_method(name) do |value = Undefined|
              ivar = "@#{name}"

              if value == Undefined
                if instance_variable_defined?(ivar)
                  instance_variable_get(ivar)
                else
                  nil
                end
              else
                raise InvalidClassAttributeValue.new(name, value) unless type === value

                instance_variable_set(ivar, value)
              end
            end
          end

          define_method(:inherited) do |klass|
            args.each { |name| klass.send(name, send(name)) }

            super(klass)
          end
        end

        extend(mod)
      end
    end
  end
end
