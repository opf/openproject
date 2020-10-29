# frozen_string_literal: true

module PDF
  module Core
    class FilterList
      def initialize
        @list = []
      end

      def <<(filter)
        case filter
        when Symbol
          @list << [filter, nil]
        when ::Hash
          filter.each do |name, params|
            @list << [name, params]
          end
        else
          raise "Can not interpret input as filter: #{filter.inspect}"
        end

        self
      end

      def normalized
        @list
      end
      alias to_a normalized

      def names
        @list.map do |(name, _)|
          name
        end
      end

      def decode_params
        @list.map do |(_, params)|
          params
        end
      end

      def inspect
        @list.inspect
      end

      def each
        @list.each do |filter|
          yield(filter)
        end
      end
    end
  end
end
