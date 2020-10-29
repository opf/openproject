# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      autoload :Charset,          'ttfunk/table/cff/charset'
      autoload :Charsets,         'ttfunk/table/cff/charsets'
      autoload :Charstring,       'ttfunk/table/cff/charstring'
      autoload :CharstringsIndex, 'ttfunk/table/cff/charstrings_index'
      autoload :Dict,             'ttfunk/table/cff/dict'
      autoload :Encoding,         'ttfunk/table/cff/encoding'
      autoload :Encodings,        'ttfunk/table/cff/encodings'
      autoload :FdSelector,       'ttfunk/table/cff/fd_selector'
      autoload :FontDict,         'ttfunk/table/cff/font_dict'
      autoload :FontIndex,        'ttfunk/table/cff/font_index'
      autoload :Header,           'ttfunk/table/cff/header'
      autoload :Index,            'ttfunk/table/cff/index'
      autoload :OneBasedIndex,    'ttfunk/table/cff/one_based_index'
      autoload :Path,             'ttfunk/table/cff/path'
      autoload :PrivateDict,      'ttfunk/table/cff/private_dict'
      autoload :SubrIndex,        'ttfunk/table/cff/subr_index'
      autoload :TopDict,          'ttfunk/table/cff/top_dict'
      autoload :TopIndex,         'ttfunk/table/cff/top_index'

      TAG = 'CFF ' # the extra space is important

      attr_reader :header, :name_index, :top_index, :string_index
      attr_reader :global_subr_index

      def tag
        TAG
      end

      def encode(new_to_old, old_to_new)
        EncodedString.new do |result|
          sub_tables = [
            header.encode,
            name_index.encode,
            top_index.encode(&:encode),
            string_index.encode,
            global_subr_index.encode
          ]

          sub_tables.each { |tb| result << tb }
          top_index[0].finalize(result, new_to_old, old_to_new)
        end
      end

      private

      def parse!
        @header = Header.new(file, offset)
        @name_index = Index.new(file, @header.table_offset + @header.length)

        @top_index = TopIndex.new(
          file, @name_index.table_offset + @name_index.length
        )

        @string_index = OneBasedIndex.new(
          file, @top_index.table_offset + @top_index.length
        )

        @global_subr_index = SubrIndex.new(
          file, @string_index.table_offset + @string_index.length
        )
      end
    end
  end
end
