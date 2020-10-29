# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class TopIndex < TTFunk::Table::Cff::Index
        def [](index)
          entry_cache[index] ||= begin
            start, finish = absolute_offsets_for(index)
            TTFunk::Table::Cff::TopDict.new(file, start, (finish - start) + 1)
          end
        end
      end
    end
  end
end
