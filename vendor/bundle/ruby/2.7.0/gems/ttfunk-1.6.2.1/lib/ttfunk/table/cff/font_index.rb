# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class FontIndex < TTFunk::Table::Cff::Index
        attr_reader :top_dict

        def initialize(top_dict, file, offset, length = nil)
          super(file, offset, length)
          @top_dict = top_dict
        end

        def [](index)
          entry_cache[index] ||= begin
            start, finish = absolute_offsets_for(index)
            TTFunk::Table::Cff::FontDict.new(
              top_dict, file, start, (finish - start) + 1
            )
          end
        end

        def finalize(new_cff_data, mapping)
          each { |font_dict| font_dict.finalize(new_cff_data, mapping) }
        end
      end
    end
  end
end
