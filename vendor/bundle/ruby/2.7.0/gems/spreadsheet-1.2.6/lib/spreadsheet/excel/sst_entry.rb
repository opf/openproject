require 'spreadsheet/encodings'

module Spreadsheet
  module Excel
##
# Shared String Table Entry
class SstEntry
  include Spreadsheet::Encodings
  attr_accessor :chars, :phonetic, :richtext, :flags, :available,
                :continued_chars, :wide
  def initialize opts = {}
    @content = nil
    @offset = opts[:offset]
    @ole    = opts[:ole]
    @reader = opts[:reader]
    @continuations = []
  end
  ##
  # Access the contents of this Shared String
  def content
    @content or begin
      data = nil
      data = @ole[@offset, @available]
      content, _ = @reader.read_string_body data, @flags, @available, @wide
      @continuations.each do |offset, len|
        @reader.continue_string(@ole[offset,len], [content, @chars])
      end
      content = client content, 'UTF-16LE'
      if @reader.memoize?
        @content = content
      end
      content
    end
  end
  ##
  # Register the offset of a String continuation
  def continue offset, size, chars
    @continued_chars -= chars
    @continuations.push [offset, size]
  end
  def continued? # :nodoc:
    @continued_chars > 0
  end
end
  end
end
