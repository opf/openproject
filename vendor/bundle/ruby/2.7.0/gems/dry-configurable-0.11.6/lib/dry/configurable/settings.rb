# frozen_string_literal: true

require 'concurrent/map'

require 'dry/equalizer'
require 'dry/configurable/constants'

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class Settings
      include Dry::Equalizer(:elements)

      include Enumerable

      # @api private
      attr_reader :elements

      # @api private
      def initialize(elements = EMPTY_ARRAY)
        initialize_elements(elements)
      end

      # @api private
      def <<(setting)
        elements[setting.name] = setting
        self
      end

      # @api private
      def [](name)
        elements[name]
      end

      # @api private
      def key?(name)
        keys.include?(name)
      end

      # @api private
      def keys
        elements.keys
      end

      # @api private
      def each(&block)
        elements.values.each(&block)
      end

      # @api private
      def pristine
        self.class.new(map(&:pristine))
      end

      private

      # @api private
      def initialize_copy(source)
        initialize_elements(source.map(&:dup))
      end

      # @api private
      def initialize_elements(elements)
        @elements = elements.each_with_object(Concurrent::Map.new) { |s, m|
          m[s.name] = s
        }
      end
    end
  end
end
