# = HTMLTokenizer
#
# Author::    Ben Giddings  (mailto:bg-rubyforge@infofiend.com)
# Copyright:: Copyright (c) 2004 Ben Giddings
# License::   Distributes under the same terms as Ruby
#
#
# This is a partial port of the functionality behind Perl's TokeParser
# Provided a page it progressively returns tokens from that page
#
# $Id: htmltokenizer.rb,v 1.7 2005/06/07 21:05:53 merc Exp $

#
# A class to tokenize HTML.
#
# Example:
#
#   page = "<HTML>
#   <HEAD>
#   <TITLE>This is the title</TITLE>
#   </HEAD>
#    <!-- Here comes the <a href=\"missing.link\">blah</a>
#    comment body
#     -->
#    <BODY>
#      <H1>This is the header</H1>
#      <P>
#        This is the paragraph, it contains
#        <a href=\"link.html\">links</a>,
#        <img src=\"blah.gif\" optional alt='images
#        are
#        really cool'>.  Ok, here is some more text and
#        <A href=\"http://another.link.com/\" target=\"_blank\">another link</A>.
#      </P>
#    </body>
#    </HTML>
#    "
#    toke = HTMLTokenizer.new(page)
#
#    assert("<h1>" == toke.getTag("h1", "h2", "h3").to_s.downcase)
#    assert(HTMLTag.new("<a href=\"link.html\">") == toke.getTag("IMG", "A"))
#    assert("links" == toke.getTrimmedText)
#    assert(toke.getTag("IMG", "A").attr_hash['optional'])
#    assert("_blank" == toke.getTag("IMG", "A").attr_hash['target'])
#
class HTMLTokenizer
  @@version = 1.0

  # Get version of HTMLTokenizer lib
  def self.version
    @@version
  end

  attr_reader :page

  # Create a new tokenizer, based on the content, used as a string.
  def initialize(content)
    @page = content.to_s
    @cur_pos = 0
  end

  # Reset the parser, setting the current position back at the stop
  def reset
    @cur_pos = 0
  end

  # Look at the next token, but don't actually grab it
  def peekNextToken
    if @cur_pos == @page.length then return nil end

    if ?< == @page[@cur_pos]
      # Next token is a tag of some kind
      if '!--' == @page[(@cur_pos + 1), 3]
        # Token is a comment
        tag_end = @page.index('-->', (@cur_pos + 1))
        if tag_end.nil?
          raise HTMLTokenizerError, "No end found to started comment:\n#{@page[@cur_pos,80]}"
        end
        # p @page[@cur_pos .. (tag_end+2)]
        HTMLComment.new(@page[@cur_pos .. (tag_end + 2)])
      else
        # Token is a html tag
        tag_end = @page.index('>', (@cur_pos + 1))
        if tag_end.nil?
          raise HTMLTokenizerError, "No end found to started tag:\n#{@page[@cur_pos,80]}"
        end
        # p @page[@cur_pos .. tag_end]
        HTMLTag.new(@page[@cur_pos .. tag_end])
      end
    else
      # Next token is text
      text_end = @page.index('<', @cur_pos)
      text_end = text_end.nil? ? -1 : (text_end - 1)
      # p @page[@cur_pos .. text_end]
      HTMLText.new(@page[@cur_pos .. text_end])
    end
  end

  # Get the next token, returns an instance of
  # * HTMLText
  # * HTMLToken
  # * HTMLTag
  def getNextToken
    token = peekNextToken
    if token
      # @page = @page[token.raw.length .. -1]
      # @page.slice!(0, token.raw.length)
      @cur_pos += token.raw.length
    end
    #p token
    #print token.raw
    return token
  end

  # Get a tag from the specified set of desired tags.
  # For example:
  # <tt>foo =  toke.getTag("h1", "h2", "h3")</tt>
  # Will return the next header tag encountered.
  def getTag(*sought_tags)
    sought_tags.collect! {|elm| elm.downcase}

    while (tag = getNextToken)
      if tag.kind_of?(HTMLTag) and
          (0 == sought_tags.length or sought_tags.include?(tag.tag_name))
        break
      end
    end
    tag
  end

  # Get all the text between the current position and the next tag
  # (if specified) or a specific later tag
  def getText(until_tag = nil)
    if until_tag.nil?
      if ?< == @page[@cur_pos]
        # Next token is a tag, not text
        ""
      else
        # Next token is text
        getNextToken.text
      end
    else
      ret_str = ""

      while (tag = peekNextToken)
        if tag.kind_of?(HTMLTag) and tag.tag_name == until_tag
          break
        end

        if ("" != tag.text)
          ret_str << (tag.text + " ")
        end
        getNextToken
      end

      ret_str
    end
  end

  # Like getText, but squeeze all whitespace, getting rid of
  # leading and trailing whitespace, and squeezing multiple
  # spaces into a single space.
  def getTrimmedText(until_tag = nil)
    getText(until_tag).strip.gsub(/\s+/m, " ")
  end

end

class HTMLTokenizerError < Exception
end

# The parent class for all three types of HTML tokens
class HTMLToken
  attr_accessor :raw

  # Initialize the token based on the raw text
  def initialize(text)
    @raw = text
  end

  # By default, return exactly the string used to create the text
  def to_s
    raw
  end

  # By default tokens have no text representation
  def text
    ""
  end

  def trimmed_text
    text.strip.gsub(/\s+/m, " ")
  end

  # Compare to another based on the raw source
  def ==(other)
    raw == other.to_s
  end
end

# Class representing text that isn't inside a tag
class HTMLText < HTMLToken
  def text
    raw
  end
end

# Class representing an HTML comment
class HTMLComment < HTMLToken
  attr_accessor :contents
  def initialize(text)
    super(text)
    temp_arr = text.scan(/^<!--\s*(.*?)\s*-->$/m)
    if temp_arr[0].nil?
      raise HTMLTokenizerError, "Text passed to HTMLComment.initialize is not a comment"
    end

    @contents = temp_arr[0][0]
  end
end

# Class representing an HTML tag
class HTMLTag < HTMLToken
  attr_reader :end_tag, :tag_name
  def initialize(text)
    super(text)
    if ?< != text[0] or ?> != text[-1]
      raise HTMLTokenizerError, "Text passed to HTMLComment.initialize is not a comment"
    end

    @attr_hash = Hash.new
    @raw = text

    tag_name = text.scan(/[\w:-]+/)[0]
    if tag_name.nil?
      raise HTMLTokenizerError, "Error, tag is nil: #{tag_name}"
    end

    if ?/ == text[1]
      # It's an end tag
      @end_tag = true
      @tag_name = '/' + tag_name.downcase
    else
      @end_tag = false
      @tag_name = tag_name.downcase
    end

    @hashed = false
  end

  # Retrieve a hash of all the tag's attributes.
  # Lazily done, so that if you don't look at a tag's attributes
  # things go quicker
  def attr_hash
    # Lazy initialize == don't build the hash until it's needed
    if !@hashed
      if !@end_tag
        # Get the attributes
        attr_arr = @raw.scan(/<[\w:-]+\s+(.*?)\/?>/m)[0]
        if attr_arr.kind_of?(Array)
          # Attributes found, parse them
          attrs = attr_arr[0]
          attr_arr = attrs.scan(/\s*([\w:-]+)(?:\s*=\s*("[^"]*"|'[^']*'|([^"'>][^\s>]*)))?/m)
          # clean up the array by:
          # * setting all nil elements to true
          # * removing enclosing quotes
          attr_arr.each {
            |item|
            val = if item[1].nil?
                    item[0]
                  elsif '"'[0] == item[1][0] or '\''[0] == item[1][0]
                    item[1][1 .. -2]
                  else
                    item[1]
                  end
            @attr_hash[item[0].downcase] = val
          }
        end
      end
      @hashed = true
    end

    #p self

    @attr_hash
  end

  # Get the 'alt' text for a tag, if it exists, or an empty string otherwise
  def text
    if !end_tag
      case tag_name
      when 'img'
        if !attr_hash['alt'].nil?
          return attr_hash['alt']
        end
      when 'applet'
        if !attr_hash['alt'].nil?
          return attr_hash['alt']
        end
      end
    end
    return ''
  end
end

