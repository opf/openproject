# frozen_string_literal: true

require 'forwardable'

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class OneBasedIndex
        extend Forwardable

        def_delegators :base_index, :each, :table_offset,
          :count, :length, :encode

        attr_reader :base_index

        def initialize(*args)
          @base_index = Index.new(*args)
        end

        def [](idx)
          if idx == 0
            raise IndexError,
              "index #{idx} was outside the bounds of the index"
          end

          base_index[idx - 1]
        end
      end
    end
  end
end
