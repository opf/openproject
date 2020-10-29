require "#{File.dirname(__FILE__)}/../duration"
require "mongoid"
require "mongoid/fields"

# Mongoid serialization support for Duration type.
module Mongoid
  module Fields
    class Duration

      # Instantiates a new Duration object
      def initialize(seconds)
        ::Duration.new(seconds)
      end

      # Converts the Duration object into a MongoDB friendly value.
      def mongoize
        self.to_i
      end

      class << self
        # Deserialize a Duration given the amount of seconds stored by Mongodb
        #
        # @param [Integer, nil] duration in seconds
        # @return [Duration] deserialized Duration
        def demongoize(seconds)
          return if !seconds
          ::Duration.new(seconds)
        end

        # Serialize a Duration or a Hash (with duration units) or a amount of seconds to
        # a BSON serializable type.
        #
        # @param [Duration, Hash, Integer] value
        # @return [Integer] duration in seconds
        def mongoize(value)
          return if value.blank?
          if value.is_a?(Hash)
            value.delete_if{|k, v| v.blank? || !::Duration::UNITS.include?(k.to_sym)}
            return if value.blank?
            ::Duration.new(value).to_i
          elsif value.respond_to?(:to_i)
            value.to_i
          end
        end

        # Converts the object that was supplied to a criteria and converts it
        # into a database friendly form.
        def evolve(object)
          case object
          when ::Duration then object.mongoize
          else object
          end
        end
      end
    end
  end
end
