# frozen_string_literal: true

module Grape
  module Util
    class LazyValue
      attr_reader :access_keys
      def initialize(value, access_keys = [])
        @value = value
        @access_keys = access_keys
      end

      def evaluate_from(configuration)
        matching_lazy_value = configuration.fetch(@access_keys)
        matching_lazy_value.evaluate
      end

      def evaluate
        @value
      end

      def lazy?
        true
      end

      def reached_by(parent_access_keys, access_key)
        @access_keys = parent_access_keys + [access_key]
        self
      end

      def to_s
        evaluate.to_s
      end
    end

    class LazyValueEnumerable < LazyValue
      def [](key)
        if @value_hash[key].nil?
          LazyValue.new(nil).reached_by(access_keys, key)
        else
          @value_hash[key].reached_by(access_keys, key)
        end
      end

      def fetch(access_keys)
        fetched_keys = access_keys.dup
        value = self[fetched_keys.shift]
        fetched_keys.any? ? value.fetch(fetched_keys) : value
      end

      def []=(key, value)
        @value_hash[key] = if value.is_a?(Hash)
                             LazyValueHash.new(value)
                           elsif value.is_a?(Array)
                             LazyValueArray.new(value)
                           else
                             LazyValue.new(value)
                           end
      end
    end

    class LazyValueArray < LazyValueEnumerable
      def initialize(array)
        super
        @value_hash = []
        array.each_with_index do |value, index|
          self[index] = value
        end
      end

      def evaluate
        evaluated = []
        @value_hash.each_with_index do |value, index|
          evaluated[index] = value.evaluate
        end
        evaluated
      end
    end

    class LazyValueHash < LazyValueEnumerable
      def initialize(hash)
        super
        @value_hash = {}.with_indifferent_access
        hash.each do |key, value|
          self[key] = value
        end
      end

      def evaluate
        evaluated = {}.with_indifferent_access
        @value_hash.each do |key, value|
          evaluated[key] =  value.evaluate
        end
        evaluated
      end
    end
  end
end
