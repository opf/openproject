# frozen_string_literal: true

require_relative 'types/build_coercer'
require_relative 'types/custom_type_coercer'
require_relative 'types/custom_type_collection_coercer'
require_relative 'types/multiple_type_coercer'
require_relative 'types/variant_collection_coercer'
require_relative 'types/json'
require_relative 'types/file'

module Grape
  module Validations
    # Module for code related to grape's system for
    # coercion and type validation of incoming request
    # parameters.
    #
    # Grape uses a number of tests and assertions to
    # work out exactly how a parameter should be handled,
    # based on the +type+ and +coerce_with+ options that
    # may be supplied to {Grape::Dsl::Parameters#requires}
    # and {Grape::Dsl::Parameters#optional}. The main
    # entry point for this process is {Types.build_coercer}.
    module Types
      # Instances of this class may be used as tokens to denote that
      # a parameter value could not be coerced.
      class InvalidValue; end

      # Types representing a single value, which are coerced.
      PRIMITIVES = [
        # Numerical
        Integer,
        Float,
        BigDecimal,
        Numeric,

        # Date/time
        Date,
        DateTime,
        Time,

        # Misc
        Grape::API::Boolean,
        String,
        Symbol,
        TrueClass,
        FalseClass
      ].freeze

      # Types representing data structures.
      STRUCTURES = [
        Hash,
        Array,
        Set
      ].freeze

      # Special custom types provided by Grape.
      SPECIAL = {
        JSON => Json,
        Array[JSON] => JsonArray,
        ::File => File,
        Rack::Multipart::UploadedFile => File
      }.freeze

      GROUPS = [
        Array,
        Hash,
        JSON,
        Array[JSON]
      ].freeze

      # Is the given class a primitive type as recognized by Grape?
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type is known by Grape as a valid
      #   type for a single value
      def self.primitive?(type)
        PRIMITIVES.include?(type)
      end

      # Is the given class a standard data structure (collection or map)
      # as recognized by Grape?
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type is known by Grape as a valid
      #   data structure type
      def self.structure?(type)
        STRUCTURES.include?(type)
      end

      # Is the declared type in fact an array of multiple allowed types?
      # For example the declaration +types: [Integer,String]+ will attempt
      # first to coerce given values to integer, but will also accept any
      # other string.
      #
      # @param type [Array<Class>,Set<Class>] type (or type list!) to check
      # @return [Boolean] +true+ if the given value will be treated as
      #   a list of types.
      def self.multiple?(type)
        (type.is_a?(Array) || type.is_a?(Set)) && type.size > 1
      end

      # Does Grape provide special coercion and validation
      # routines for the given class? This does not include
      # automatic handling for primitives, structures and
      # otherwise recognized types. See {Types::SPECIAL}.
      #
      # @param type [Class] type to check
      # @return [Boolean] +true+ if special routines are available
      def self.special?(type)
        SPECIAL.key? type
      end

      # Is the declared type a supported group type?
      # Currently supported group types are Array, Hash, JSON, and Array[JSON]
      #
      # @param type [Array<Class>,Class] type to check
      # @return [Boolean] +true+ if the type is a supported group type
      def self.group?(type)
        GROUPS.include? type
      end

      # A valid custom type must implement a class-level `parse` method, taking
      # one String argument and returning the parsed value in its correct type.
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type can be used as a custom type
      def self.custom?(type)
        !primitive?(type) &&
          !structure?(type) &&
          !multiple?(type) &&
          type.respond_to?(:parse) &&
          type.method(:parse).arity == 1
      end

      # Is the declared type an +Array+ or +Set+ of a {#custom?} type?
      #
      # @param type [Array<Class>,Class] type to check
      # @return [Boolean] true if +type+ is a collection of a type that implements
      #   its own +#parse+ method.
      def self.collection_of_custom?(type)
        (type.is_a?(Array) || type.is_a?(Set)) &&
          type.length == 1 &&
          (custom?(type.first) || special?(type.first))
      end

      def self.map_special(type)
        SPECIAL.fetch(type, type)
      end
    end
  end
end
