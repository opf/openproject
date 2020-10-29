# frozen_string_literal: true

require_relative 'array_coercer'
require_relative 'set_coercer'
require_relative 'primitive_coercer'

module Grape
  module Validations
    module Types
      # Chooses the best coercer for the given type. For example, if the type
      # is Integer, it will return a coercer which will be able to coerce a value
      # to the integer.
      #
      # There are a few very special coercers which might be returned.
      #
      # +Grape::Types::MultipleTypeCoercer+ is a coercer which is returned when
      # the given type implies values in an array with different types.
      # For example, +[Integer, String]+ allows integer and string values in
      # an array.
      #
      # +Grape::Types::CustomTypeCoercer+ is a coercer which is returned when
      # a method is specified by a user with +coerce_with+ option or the user
      # specifies a custom type which implements requirments of
      # +Grape::Types::CustomTypeCoercer+.
      #
      # +Grape::Types::CustomTypeCollectionCoercer+ is a very similar to the
      # previous one, but it expects an array or set of values having a custom
      # type implemented by the user.
      #
      # There is also a group of custom types implemented by Grape, check
      # +Grape::Validations::Types::SPECIAL+ to get the full list.
      #
      # @param type [Class] the type to which input strings
      #   should be coerced
      # @param method [Class,#call] the coercion method to use
      # @return [Object] object to be used
      #   for coercion and type validation
      def self.build_coercer(type, method: nil, strict: false)
        cache_instance(type, method, strict) do
          create_coercer_instance(type, method, strict)
        end
      end

      def self.create_coercer_instance(type, method, strict)
        # Maps a custom type provided by Grape, it doesn't map types wrapped by collections!!!
        type = Types.map_special(type)

        # Use a special coercer for multiply-typed parameters.
        if Types.multiple?(type)
          MultipleTypeCoercer.new(type, method)

        # Use a special coercer for custom types and coercion methods.
        elsif method || Types.custom?(type)
          CustomTypeCoercer.new(type, method)

        # Special coercer for collections of types that implement a parse method.
        # CustomTypeCoercer (above) already handles such types when an explicit coercion
        # method is supplied.
        elsif Types.collection_of_custom?(type)
          Types::CustomTypeCollectionCoercer.new(
            Types.map_special(type.first), type.is_a?(Set)
          )
        else
          DryTypeCoercer.coercer_instance_for(type, strict)
        end
      end

      def self.cache_instance(type, method, strict, &_block)
        key = cache_key(type, method, strict)

        return @__cache[key] if @__cache.key?(key)

        instance = yield

        @__cache_write_lock.synchronize do
          @__cache[key] = instance
        end

        instance
      end

      def self.cache_key(type, method, strict)
        [type, method, strict].each_with_object(+'_') do |val, memo|
          next if val.nil?

          memo << '_' << val.to_s
        end
      end

      instance_variable_set(:@__cache,            {})
      instance_variable_set(:@__cache_write_lock, Mutex.new)
    end
  end
end
