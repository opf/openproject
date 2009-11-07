module CodeRay
module Encoders

  # = XML Encoder
  #
  # Uses REXML. Very slow.
  class XML < Encoder

    include Streamable
    register_for :xml

    FILE_EXTENSION = 'xml'

    require 'rexml/document'

    DEFAULT_OPTIONS = {
      :tab_width => 8,
      :pretty => -1,
      :transitive => false,
    }

  protected

    def setup options
      @doc = REXML::Document.new
      @doc << REXML::XMLDecl.new
      @tab_width = options[:tab_width]
      @root = @node = @doc.add_element('coderay-tokens')
    end

    def finish options
      @out = ''
      @doc.write @out, options[:pretty], options[:transitive], true
      @out
    end
    
    def text_token text, kind
      if kind == :space
        token = @node
      else
        token = @node.add_element kind.to_s
      end
      text.scan(/(\x20+)|(\t+)|(\n)|[^\x20\t\n]+/) do |space, tab, nl|
        case
        when space
          token << REXML::Text.new(space, true)
        when tab
          token << REXML::Text.new(tab, true)
        when nl
          token << REXML::Text.new(nl, true)
        else
          token << REXML::Text.new($&)
        end
      end
    end

    def open_token kind
      @node = @node.add_element kind.to_s
    end

    def close_token kind
      if @node == @root
        raise 'no token to close!'
      end
      @node = @node.parent
    end

  end

end
end
