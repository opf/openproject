module CodeRay
module Scanners

  load :html
  load :ruby

  # Nitro XHTML Scanner
  class NitroXHTML < Scanner

    include Streamable
    register_for :nitro_xhtml
    file_extension :xhtml
    title 'Nitro XHTML'

    KINDS_NOT_LOC = HTML::KINDS_NOT_LOC
    
    NITRO_RUBY_BLOCK = /
      <\?r
      (?>
        [^\?]*
        (?> \?(?!>) [^\?]* )*
      )
      (?: \?> )?
    |
      <ruby>
      (?>
        [^<]*
        (?> <(?!\/ruby>) [^<]* )*
      )
      (?: <\/ruby> )?
    |
      <%
      (?>
        [^%]*
        (?> %(?!>) [^%]* )*
      )
      (?: %> )?
    /mx

    NITRO_VALUE_BLOCK = /
      \#
      (?:
        \{
        [^{}]*
        (?>
          \{ [^}]* \}
          (?> [^{}]* )
        )*
        \}?
      | \| [^|]* \|?
      | \( [^)]* \)?
      | \[ [^\]]* \]?
      | \\ [^\\]* \\?
      )
    /x

    NITRO_ENTITY = /
      % (?: \#\d+ | \w+ ) ;
    /

    START_OF_RUBY = /
      (?=[<\#%])
      < (?: \?r | % | ruby> )
    | \# [{(|]
    | % (?: \#\d+ | \w+ ) ;
    /x

    CLOSING_PAREN = Hash.new do |h, p|
      h[p] = p
    end.update( {
      '(' => ')',
      '[' => ']',
      '{' => '}',
    } )

  private

    def setup
      @ruby_scanner = CodeRay.scanner :ruby, :tokens => @tokens, :keep_tokens => true
      @html_scanner = CodeRay.scanner :html, :tokens => @tokens, :keep_tokens => true, :keep_state => true
    end

    def reset_instance
      super
      @html_scanner.reset
    end

    def scan_tokens tokens, options

      until eos?

        if (match = scan_until(/(?=#{START_OF_RUBY})/o) || scan_until(/\z/)) and not match.empty?
          @html_scanner.tokenize match

        elsif match = scan(/#{NITRO_VALUE_BLOCK}/o)
          start_tag = match[0,2]
          delimiter = CLOSING_PAREN[start_tag[1,1]]
          end_tag = match[-1,1] == delimiter ? delimiter : ''
          tokens << [:open, :inline]
          tokens << [start_tag, :inline_delimiter]
          code = match[start_tag.size .. -1 - end_tag.size]
          @ruby_scanner.tokenize code
          tokens << [end_tag, :inline_delimiter] unless end_tag.empty?
          tokens << [:close, :inline]

        elsif match = scan(/#{NITRO_RUBY_BLOCK}/o)
          start_tag = '<?r'
          end_tag = match[-2,2] == '?>' ? '?>' : ''
          tokens << [:open, :inline]
          tokens << [start_tag, :inline_delimiter]
          code = match[start_tag.size .. -(end_tag.size)-1]
          @ruby_scanner.tokenize code
          tokens << [end_tag, :inline_delimiter] unless end_tag.empty?
          tokens << [:close, :inline]

        elsif entity = scan(/#{NITRO_ENTITY}/o)
          tokens << [entity, :entity]
        
        elsif scan(/%/)
          tokens << [matched, :error]

        else
          raise_inspect 'else-case reached!', tokens
          
        end

      end

      tokens

    end

  end

end
end
