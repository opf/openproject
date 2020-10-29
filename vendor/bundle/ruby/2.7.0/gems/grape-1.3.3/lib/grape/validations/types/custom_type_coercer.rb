# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class will detect type classes that implement
      # a class-level +parse+ method. The method should accept one
      # +String+ argument and should return the value coerced to
      # the appropriate type. The method may raise an exception if
      # there are any problems parsing the string.
      #
      # Alternately an optional +method+ may be supplied (see the
      # +coerce_with+ option of {Grape::Dsl::Parameters#requires}).
      # This may be any class or object implementing +parse+ or +call+,
      # with the same contract as described above.
      #
      # Type Checking
      # -------------
      #
      # Calls to +coerced?+ will consult this class to check
      # that the coerced value produced above is in fact of the
      # expected type. By default this class performs a basic check
      # against the type supplied, but this behaviour will be
      # overridden if the class implements a class-level
      # +coerced?+ or +parsed?+ method. This method
      # will receive a single parameter that is the coerced value
      # and should return +true+ if the value meets type expectations.
      # Arbitrary assertions may be made here but the grape validation
      # system should be preferred.
      #
      # Alternately a proc or other object responding to +call+ may be
      # supplied in place of a type. This should implement the same
      # contract as +coerced?+, and must be supplied with a coercion
      # +method+.
      class CustomTypeCoercer
        # A new coercer for the given type specification
        # and coercion method.
        #
        # @param type [Class,#coerced?,#parsed?,#call?]
        #   specifier for the target type. See class docs.
        # @param method [#parse,#call]
        #   optional coercion method. See class docs.
        def initialize(type, method = nil)
          coercion_method = infer_coercion_method type, method
          @method = enforce_symbolized_keys type, coercion_method
          @type_check = infer_type_check(type)
        end

        # Coerces the given value.
        #
        # @param value [String] value to be coerced, in grape
        #   this should always be a string.
        # @return [Object] the coerced result
        def call(val)
          return if val.nil?

          coerced_val = @method.call(val)
          return InvalidValue.new unless coerced?(coerced_val)
          coerced_val
        end

        def coerced?(val)
          val.nil? || @type_check.call(val)
        end

        private

        # Determine the coercion method we're expected to use
        # based on the parameters given.
        #
        # @param type see #new
        # @param method see #new
        # @return [#call] coercion method
        def infer_coercion_method(type, method)
          if method
            if method.respond_to? :parse
              method.method :parse
            else
              method
            end
          else
            # Try to use parse() declared on the target type.
            # This may raise an exception, but we are out of ideas anyway.
            type.method :parse
          end
        end

        # Determine how the type validity of a coerced
        # value should be decided.
        #
        # @param type see #new
        # @return [#call] a procedure which accepts a single parameter
        #   and returns +true+ if the passed object is of the correct type.
        def infer_type_check(type)
          # First check for special class methods
          if type.respond_to? :coerced?
            type.method :coerced?
          elsif type.respond_to? :parsed?
            type.method :parsed?
          elsif type.respond_to? :call
            # Arbitrary proc passed for type validation.
            # Note that this will fail unless a method is also
            # passed, or if the type also implements a parse() method.
            type
          elsif type.is_a?(Enumerable)
            ->(value) { value.respond_to?(:all?) && value.all? { |item| item.is_a? type[0] } }
          else
            # By default, do a simple type check
            ->(value) { value.is_a? type }
          end
        end

        # Enforce symbolized keys for complex types
        # by wrapping the coercion method such that
        # any Hash objects in the immediate heirarchy
        # have their keys recursively symbolized.
        # This helps common libs such as JSON to work easily.
        #
        # @param type see #new
        # @param method see #infer_coercion_method
        # @return [#call] +method+ wrapped in an additional
        #   key-conversion step, or just returns +method+
        #   itself if no conversion is deemed to be
        #   necessary.
        def enforce_symbolized_keys(type, method)
          # Collections have all values processed individually
          if [Array, Set].include?(type)
            lambda do |val|
              method.call(val).tap do |new_val|
                new_val.map do |item|
                  item.is_a?(Hash) ? symbolize_keys(item) : item
                end
              end
            end

          # Hash objects are processed directly
          elsif type == Hash
            lambda do |val|
              symbolize_keys method.call(val)
            end

          # Simple types are not processed.
          # This includes Array<primitive> types.
          else
            method
          end
        end

        def symbolize_keys!(hash)
          hash.each_key do |key|
            hash[key.to_sym] = hash.delete(key) if key.respond_to?(:to_sym)
          end
          hash
        end

        def symbolize_keys(hash)
          hash.inject({}) do |new_hash, (key, value)|
            new_key = key.respond_to?(:to_sym) ? key.to_sym : key
            new_hash.merge!(new_key => value)
          end
        end
      end
    end
  end
end
