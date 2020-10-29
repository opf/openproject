# frozen_string_literal: true

# Based on https://github.com/HornsAndHooves/lazy_object

module Grape
  module Util
    class LazyObject < BasicObject
      attr_reader :callable

      def initialize(&callable)
        @callable = callable
      end

      def __target_object__
        @__target_object__ ||= callable.call
      end

      def ==(other)
        __target_object__ == other
      end

      def !=(other)
        __target_object__ != other
      end

      def !
        !__target_object__
      end

      def method_missing(method_name, *args, &block)
        if __target_object__.respond_to?(method_name)
          __target_object__.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_priv = false)
        __target_object__.respond_to?(method_name, include_priv)
      end
    end
  end
end
