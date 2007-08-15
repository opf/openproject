module CodeRay
module Scanners

  load :html
  load :ruby

  # RHTML Scanner
  #
  # $Id$
  class RHTML < Scanner

    include Streamable
    register_for :rhtml

    ERB_RUBY_BLOCK = /
      <%(?!%)[=-]?
      (?>
        [^\-%]*    # normal*
        (?>        # special
          (?: %(?!>) | -(?!%>) )
          [^\-%]*  # normal*
        )*
      )
      (?: -?%> )?
    /x

    START_OF_ERB = /
      <%(?!%)
    /x

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

        if (match = scan_until(/(?=#{START_OF_ERB})/o) || scan_until(/\z/)) and not match.empty?
          @html_scanner.tokenize match

        elsif match = scan(/#{ERB_RUBY_BLOCK}/o)
          start_tag = match[/\A<%[-=]?/]
          end_tag = match[/-?%?>?\z/]
          tokens << [:open, :inline]
          tokens << [start_tag, :inline_delimiter]
          code = match[start_tag.size .. -1 - end_tag.size]
          @ruby_scanner.tokenize code
          tokens << [end_tag, :inline_delimiter] unless end_tag.empty?
          tokens << [:close, :inline]

        else
          raise_inspect 'else-case reached!', tokens
        end

      end

      tokens

    end

  end

end
end
