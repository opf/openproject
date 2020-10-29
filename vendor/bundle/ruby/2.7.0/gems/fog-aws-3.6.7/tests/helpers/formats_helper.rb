# frozen_string_literal: true

require 'fog/schema/data_validator'

# format related hackery
# allows both true.is_a?(Fog::Boolean) and false.is_a?(Fog::Boolean)
# allows both nil.is_a?(Fog::Nullable::String) and ''.is_a?(Fog::Nullable::String)
module Fog
  module Boolean; end
  module Nullable
    module Boolean; end
    module Integer; end
    module String; end
    module Time; end
    module Float; end
    module Hash; end
    module Array; end
  end
end
[FalseClass, TrueClass].each { |klass| klass.send(:include, Fog::Boolean) }
[FalseClass, TrueClass, NilClass, Fog::Boolean].each { |klass| klass.send(:include, Fog::Nullable::Boolean) }
[NilClass, String].each { |klass| klass.send(:include, Fog::Nullable::String) }
[NilClass, Time].each { |klass| klass.send(:include, Fog::Nullable::Time) }
[Integer, NilClass].each { |klass| klass.send(:include, Fog::Nullable::Integer) }
[Float, NilClass].each { |klass| klass.send(:include, Fog::Nullable::Float) }
[Hash, NilClass].each { |klass| klass.send(:include, Fog::Nullable::Hash) }
[Array, NilClass].each { |klass| klass.send(:include, Fog::Nullable::Array) }

module Shindo
  # Generates a Shindo test that compares a hash schema to the result
  # of the passed in block returning true if they match.
  #
  # The schema that is passed in is a Hash or Array of hashes that
  # have Classes in place of values. When checking the schema the
  # value should match the Class.
  #
  # Strict mode will fail if the data has additional keys. Setting
  # +strict+ to +false+ will allow additional keys to appear.
  #
  # @param [Hash] schema A Hash schema
  # @param [Hash] options Options to change validation rules
  # @option options [Boolean] :allow_extra_keys
  #     If +true+ does not fail when keys are in the data that are
  #     not specified in the schema. This allows new values to
  #     appear in API output without breaking the check.
  # @option options [Boolean] :allow_optional_rules
  #     If +true+ does not fail if extra keys are in the schema
  #     that do not match the data. Not recommended!
  # @yield Data to check with schema
  #
  # @example Using in a test
  #     Shindo.tests("comparing welcome data against schema") do
  #       data = {:welcome => "Hello" }
  #       data_matches_schema(:welcome => String) { data }
  #     end
  #
  #     comparing welcome data against schema
  #     + data matches schema
  #
  # @example Example schema
  #     {
  #       "id" => String,
  #       "ram" => Integer,
  #       "disks" => [
  #         {
  #           "size" => Float
  #         }
  #       ],
  #       "dns_name" => Fog::Nullable::String,
  #       "active" => Fog::Boolean,
  #       "created" => DateTime
  #     }
  #
  # @return [Boolean]
  class Tests
    def data_matches_schema(schema, options = {})
      test('data matches schema') do
        validator = Fog::Schema::DataValidator.new
        valid = validator.validate(yield, schema, options)
        @message = validator.message unless valid
        valid
      end
    end

    # @deprecated #formats is deprecated. Use #data_matches_schema instead
    def formats(format, strict = true)
      test('has proper format') do
        if strict
          options = { allow_extra_keys: false, allow_optional_rules: true }
        else
          options = { allow_extra_keys: true, allow_optional_rules: true }
        end
        validator = Fog::Schema::DataValidator.new
        valid = validator.validate(yield, format, options)
        @message = validator.message unless valid
        valid
      end
    end
  end
end
