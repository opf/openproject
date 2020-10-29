# coding: utf-8
# frozen_string_literal: true

################################################################################
#
# Copyright (C) 2008 James Healy (jimmy@deefa.com)
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
################################################################################

class PDF::Reader

  # wraps a string containing a PDF CMap and provides convenience methods for
  # extracting various useful information.
  #
  class CMap # :nodoc:
    CMAP_KEYWORDS = {
      "begincodespacerange" => 1,
      "endcodespacerange" => 1,
      "beginbfchar" => 1,
      "endbfchar" => 1,
      "beginbfrange" => 1,
      "endbfrange" => 1,
      "begin" => 1,
      "begincmap" => 1,
      "def" => 1
    }

    attr_reader :map

    def initialize(data)
      @map = {}
      process_data(data)
    end

    def process_data(data)
      parser = build_parser(data)
      mode = nil
      instructions = []

      while token = parser.parse_token(CMAP_KEYWORDS)
        if token == "beginbfchar"
          mode = :char
        elsif token == "endbfchar"
          process_bfchar_instructions(instructions)
          instructions = []
          mode = nil
        elsif token == "beginbfrange"
          mode = :range
        elsif token == "endbfrange"
          process_bfrange_instructions(instructions)
          instructions = []
          mode = nil
        elsif mode == :char || mode == :range
          instructions << token
        end
      end
    end

    def size
      @map.size
    end

    # Convert a glyph code into one or more Codepoints.
    #
    # Returns an array of Integers.
    #
    def decode(c)
      # TODO: implement the conversion
      return c unless Integer === c
      @map[c]
    end

    private

    def build_parser(instructions)
      buffer = Buffer.new(StringIO.new(instructions))
      Parser.new(buffer)
    end

    # The following includes some manual decoding of UTF-16BE strings into unicode codepoints. In
    # theory we could replace all the UTF-16 code with something based on Ruby's encoding support:
    #
    #    str.dup.force_encoding("utf-16be").encode!("utf-8").unpack("U*")
    #
    # However, some cmaps contain broken surrogate pairs and the ruby encoding support raises an
    # exception when we try converting broken UTF-16 to UTF-8
    #
    def str_to_int(str)
      return nil if str.nil? || str.size == 0
      unpacked_string = if str.bytesize == 1 # UTF-8
        str.unpack("C*")
      else # UTF-16
         str.unpack("n*")
      end
      result = []
      while unpacked_string.any? do
        if unpacked_string.size >= 2 && unpacked_string[0] > 0xD800 && unpacked_string[0] < 0xDBFF
          # this is a Unicode UTF-16 "Surrogate Pair" see Unicode Spec. Chapter 3.7
          # lets convert to a UTF-32. (the high bit is between 0xD800-0xDBFF, the
          # low bit is between 0xDC00-0xDFFF) for example: U+1D44E (U+D835 U+DC4E)
          points = [unpacked_string.shift, unpacked_string.shift]
          result << (points[0] - 0xD800) * 0x400 + (points[1] - 0xDC00) + 0x10000
        else
          result << unpacked_string.shift
        end
      end
      result
    end

    def process_bfchar_instructions(instructions)
      instructions.each_slice(2) do |one, two|
        find    = str_to_int(one)
        replace = str_to_int(two)
        @map[find.first] = replace
      end
    end

    def process_bfrange_instructions(instructions)
      instructions.each_slice(3) do |start, finish, to|
        if start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(String)
          bfrange_type_one(start, finish, to)
        elsif start.kind_of?(String) && finish.kind_of?(String) && to.kind_of?(Array)
          bfrange_type_two(start, finish, to)
        else
          raise "invalid bfrange section"
        end
      end
    end

    def bfrange_type_one(start_code, end_code, dst)
      start_code = str_to_int(start_code)[0]
      end_code   = str_to_int(end_code)[0]
      dst        = str_to_int(dst)

      # add all values in the range to our mapping
      (start_code..end_code).each_with_index do |val, idx|
        @map[val] = dst.length == 1 ? [dst[0] + idx] : [dst[0], dst[1] + 1]
      end
    end

    def bfrange_type_two(start_code, end_code, dst)
      start_code = str_to_int(start_code)[0]
      end_code   = str_to_int(end_code)[0]
      from_range = (start_code..end_code)

      # add all values in the range to our mapping
      from_range.each_with_index do |val, idx|
        @map[val] = str_to_int(dst[idx])
      end
    end
  end
end
