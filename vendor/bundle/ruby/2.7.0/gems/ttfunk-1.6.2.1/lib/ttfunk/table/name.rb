# frozen_string_literal: true

require_relative '../table'
require 'digest/sha1'

module TTFunk
  class Table
    class Name < Table
      class NameString < ::String
        attr_reader :platform_id
        attr_reader :encoding_id
        attr_reader :language_id

        def initialize(text, platform_id, encoding_id, language_id)
          super(text)
          @platform_id = platform_id
          @encoding_id = encoding_id
          @language_id = language_id
        end

        def strip_extended
          stripped = gsub(/[\x00-\x19\x80-\xff]/n, '')
          stripped = '[not-postscript]' if stripped.empty?
          stripped
        end
      end

      attr_reader :entries
      attr_reader :strings

      attr_reader :copyright
      attr_reader :font_family
      attr_reader :font_subfamily
      attr_reader :unique_subfamily
      attr_reader :font_name
      attr_reader :version
      attr_reader :trademark
      attr_reader :manufacturer
      attr_reader :designer
      attr_reader :description
      attr_reader :vendor_url
      attr_reader :designer_url
      attr_reader :license
      attr_reader :license_url
      attr_reader :preferred_family
      attr_reader :preferred_subfamily
      attr_reader :compatible_full
      attr_reader :sample_text

      COPYRIGHT_NAME_ID = 0
      FONT_FAMILY_NAME_ID = 1
      FONT_SUBFAMILY_NAME_ID = 2
      UNIQUE_SUBFAMILY_NAME_ID = 3
      FONT_NAME_NAME_ID = 4
      VERSION_NAME_ID = 5
      POSTSCRIPT_NAME_NAME_ID = 6
      TRADEMARK_NAME_ID = 7
      MANUFACTURER_NAME_ID = 8
      DESIGNER_NAME_ID = 9
      DESCRIPTION_NAME_ID = 10
      VENDOR_URL_NAME_ID = 11
      DESIGNER_URL_NAME_ID = 12
      LICENSE_NAME_ID = 13
      LICENSE_URL_NAME_ID = 14
      PREFERRED_FAMILY_NAME_ID = 16
      PREFERRED_SUBFAMILY_NAME_ID = 17
      COMPATIBLE_FULL_NAME_ID = 18
      SAMPLE_TEXT_NAME_ID = 19

      def self.encode(names, key = '')
        tag = Digest::SHA1.hexdigest(key)[0, 6]

        postscript_name = NameString.new(
          "#{tag}+#{names.postscript_name}", 1, 0, 0
        )

        strings = names.strings.dup
        strings[6] = [postscript_name]
        str_count = strings.inject(0) { |sum, (_, list)| sum + list.length }

        table = [0, str_count, 6 + 12 * str_count].pack('n*')
        strtable = +''

        items = []
        strings.each do |id, list|
          list.each do |string|
            items << [id, string]
          end
        end
        items = items.sort_by do |id, string|
          [string.platform_id, string.encoding_id, string.language_id, id]
        end
        items.each do |id, string|
          table << [
            string.platform_id, string.encoding_id, string.language_id, id,
            string.length, strtable.length
          ].pack('n*')
          strtable << string
        end

        table << strtable
      end

      def postscript_name
        return @postscript_name if @postscript_name

        font_family.first || 'unnamed'
      end

      private

      def parse!
        count, string_offset = read(6, 'x2n*')

        @entries = []
        count.times do
          platform, encoding, language, id, length, start_offset =
            read(12, 'n*')
          @entries << {
            platform_id: platform,
            encoding_id: encoding,
            language_id: language,
            name_id: id,
            length: length,
            offset: offset + string_offset + start_offset,
            text: nil
          }
        end

        @strings = Hash.new { |h, k| h[k] = [] }

        count.times do |i|
          io.pos = @entries[i][:offset]
          @entries[i][:text] = io.read(@entries[i][:length])
          @strings[@entries[i][:name_id]] << NameString.new(
            @entries[i][:text] || '',
            @entries[i][:platform_id],
            @entries[i][:encoding_id],
            @entries[i][:language_id]
          )
        end

        # should only be ONE postscript name

        @copyright = @strings[COPYRIGHT_NAME_ID]
        @font_family = @strings[FONT_FAMILY_NAME_ID]
        @font_subfamily = @strings[FONT_SUBFAMILY_NAME_ID]
        @unique_subfamily = @strings[UNIQUE_SUBFAMILY_NAME_ID]
        @font_name = @strings[FONT_NAME_NAME_ID]
        @version = @strings[VERSION_NAME_ID]

        unless @strings[POSTSCRIPT_NAME_NAME_ID].empty?
          @postscript_name = @strings[POSTSCRIPT_NAME_NAME_ID]
                             .first.strip_extended
        end

        @trademark = @strings[TRADEMARK_NAME_ID]
        @manufacturer = @strings[MANUFACTURER_NAME_ID]
        @designer = @strings[DESIGNER_NAME_ID]
        @description = @strings[DESCRIPTION_NAME_ID]
        @vendor_url = @strings[VENDOR_URL_NAME_ID]
        @designer_url = @strings[DESIGNER_URL_NAME_ID]
        @license = @strings[LICENSE_NAME_ID]
        @license_url = @strings[LICENSE_URL_NAME_ID]
        @preferred_family = @strings[PREFERRED_FAMILY_NAME_ID]
        @preferred_subfamily = @strings[PREFERRED_SUBFAMILY_NAME_ID]
        @compatible_full = @strings[COMPATIBLE_FULL_NAME_ID]
        @sample_text = @strings[SAMPLE_TEXT_NAME_ID]
      end
    end
  end
end
