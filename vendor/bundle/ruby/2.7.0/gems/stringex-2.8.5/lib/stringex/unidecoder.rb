# encoding: UTF-8

require 'yaml'
require 'stringex/localization'

module Stringex
  module Unidecoder
    # Contains Unicode codepoints, loading as needed from YAML files
    CODEPOINTS = Hash.new{|h, k|
      h[k] = ::YAML.load_file(File.join(File.expand_path(File.dirname(__FILE__)), "unidecoder_data", "#{k}.yml"))
    } unless defined?(CODEPOINTS)

    class << self
      # Returns string with its UTF-8 characters transliterated to ASCII ones
      #
      # You're probably better off just using the added String#to_ascii
      def decode(string)
        string.chars.map{|char| decoded(char)}.join
      end

      # Returns character for the given Unicode codepoint
      def encode(codepoint)
        ["0x#{codepoint}".to_i(16)].pack("U")
      end

      # Returns Unicode codepoint for the given character
      def get_codepoint(character)
        "%04x" % character.unpack("U")[0]
      end

      # Returns string indicating which file (and line) contains the
      # transliteration value for the character
      def in_yaml_file(character)
        unpacked = character.unpack("U")[0]
        "#{code_group(unpacked)}.yml (line #{grouped_point(unpacked) + 2})"
      end

    private

      def decoded(character)
        localized(character) || from_yaml(character)
      end

      def localized(character)
        Localization.translate(:transliterations, character)
      end

      def from_yaml(character)
        return character unless character.ord > 128
        unpacked = character.unpack("U")[0]
        CODEPOINTS[code_group(unpacked)][grouped_point(unpacked)]
      rescue
        # Hopefully this won't come up much
        # TODO: Make this note something to the user that is reportable to me perhaps
        "?"
      end

      # Returns the Unicode codepoint grouping for the given character
      def code_group(unpacked_character)
        "x%02x" % (unpacked_character >> 8)
      end

      # Returns the index of the given character in the YAML file for its codepoint group
      def grouped_point(unpacked_character)
        unpacked_character & 255
      end
    end
  end
end

module Stringex
  module StringExtensions
    module PublicInstanceMethods
      # Returns string with its UTF-8 characters transliterated to ASCII ones. Example:
      #
      #   "⠋⠗⠁⠝⠉⠑".to_ascii #=> "france"
      def to_ascii
        Stringex::Unidecoder.decode(self)
      end
    end
  end
end
