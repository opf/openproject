# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class CharstringsIndex < TTFunk::Table::Cff::Index
        attr_reader :top_dict

        def initialize(top_dict, *remaining_args)
          super(*remaining_args)
          @top_dict = top_dict
        end

        def [](index)
          entry_cache[index] ||= TTFunk::Table::Cff::Charstring.new(
            index, top_dict, font_dict_for(index), super
          )
        end

        # gets passed a mapping of new => old glyph ids
        def encode(mapping)
          super() do |_entry, index|
            self[mapping[index]].encode if mapping.include?(index)
          end
        end

        private

        def font_dict_for(index)
          # only CID-keyed fonts contain an FD selector and font dicts
          if top_dict.is_cid_font?
            fd_index = top_dict.font_dict_selector[index]
            top_dict.font_index[fd_index]
          end
        end
      end
    end
  end
end
