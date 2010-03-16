module CodeRay
module Scanners

  load :java

  class Groovy < Java

    include Streamable
    register_for :groovy
    
    # TODO: Check this!
    GROOVY_KEYWORDS = %w[
      as assert def in
    ]
    KEYWORDS_EXPECTING_VALUE = WordList.new.add %w[
      case instanceof new return throw typeof while as assert in
    ]
    GROOVY_MAGIC_VARIABLES = %w[ it ]
    
    IDENT_KIND = Java::IDENT_KIND.dup.
      add(GROOVY_KEYWORDS, :keyword).
      add(GROOVY_MAGIC_VARIABLES, :local_variable)
    
    ESCAPE = / [bfnrtv$\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} /x  # no 4-byte unicode chars? U[a-fA-F0-9]{8}
    REGEXP_ESCAPE =  / [bfnrtv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} | \d | [bBdDsSwW\/] /x
    
    # TODO: interpretation inside ', ", /
    STRING_CONTENT_PATTERN = {
      "'" => /(?>\\[^\\'\n]+|[^\\'\n]+)+/,
      '"' => /[^\\$"\n]+/,
      "'''" => /(?>[^\\']+|'(?!''))+/,
      '"""' => /(?>[^\\$"]+|"(?!""))+/,
      '/' => /[^\\$\/\n]+/,
    }
    
    def scan_tokens tokens, options

      state = :initial
      inline_block_stack = []
      inline_block_paren_depth = nil
      string_delimiter = nil
      import_clause = class_name_follows = last_token = after_def = false
      value_expected = true

      until eos?

        kind = nil
        match = nil
        
        case state

        when :initial

          if match = scan(/ \s+ | \\\n /x)
            tokens << [match, :space]
            if match.index ?\n
              import_clause = after_def = false
              value_expected = true unless value_expected
            end
            next
          
          elsif scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
            value_expected = true
            after_def = false
            kind = :comment
          
          elsif bol? && scan(/ \#!.* /x)
            kind = :doctype
          
          elsif import_clause && scan(/ (?!as) #{IDENT} (?: \. #{IDENT} )* (?: \.\* )? /ox)
            after_def = value_expected = false
            kind = :include
          
          elsif match = scan(/ #{IDENT} | \[\] /ox)
            kind = IDENT_KIND[match]
            value_expected = (kind == :keyword) && KEYWORDS_EXPECTING_VALUE[match]
            if last_token == '.'
              kind = :ident
            elsif class_name_follows
              kind = :class
              class_name_follows = false
            elsif after_def && check(/\s*[({]/)
              kind = :method
              after_def = false
            elsif kind == :ident && last_token != '?' && check(/:/)
              kind = :key
            else
              class_name_follows = true if match == 'class' || (import_clause && match == 'as')
              import_clause = match == 'import'
              after_def = true if match == 'def'
            end
          
          elsif scan(/;/)
            import_clause = after_def = false
            value_expected = true
            kind = :operator
          
          elsif scan(/\{/)
            class_name_follows = after_def = false
            value_expected = true
            kind = :operator
            if !inline_block_stack.empty?
              inline_block_paren_depth += 1
            end
          
          # TODO: ~'...', ~"..." and ~/.../ style regexps
          elsif match = scan(/ \.\.<? | \*?\.(?!\d)@? | \.& | \?:? | [,?:(\[] | -[->] | \+\+ |
              && | \|\| | \*\*=? | ==?~ | <=?>? | [-+*%^~&|>=!]=? | <<<?=? | >>>?=? /x)
            value_expected = true
            value_expected = :regexp if match == '~'
            after_def = false
            kind = :operator
          
          elsif match = scan(/ [)\]}] /x)
            value_expected = after_def = false
            if !inline_block_stack.empty? && match == '}'
              inline_block_paren_depth -= 1
              if inline_block_paren_depth == 0  # closing brace of inline block reached
                tokens << [match, :inline_delimiter]
                tokens << [:close, :inline]
                state, string_delimiter, inline_block_paren_depth = inline_block_stack.pop
                next
              end
            end
            kind = :operator
          
          elsif check(/[\d.]/)
            after_def = value_expected = false
            if scan(/0[xX][0-9A-Fa-f]+/)
              kind = :hex
            elsif scan(/(?>0[0-7]+)(?![89.eEfF])/)
              kind = :oct
            elsif scan(/\d+[fFdD]|\d*\.\d+(?:[eE][+-]?\d+)?[fFdD]?|\d+[eE][+-]?\d+[fFdD]?/)
              kind = :float
            elsif scan(/\d+[lLgG]?/)
              kind = :integer
            end

          elsif match = scan(/'''|"""/)
            after_def = value_expected = false
            state = :multiline_string
            tokens << [:open, :string]
            string_delimiter = match
            kind = :delimiter
          
          # TODO: record.'name'
          elsif match = scan(/["']/)
            after_def = value_expected = false
            state = match == '/' ? :regexp : :string
            tokens << [:open, state]
            string_delimiter = match
            kind = :delimiter

          elsif value_expected && (match = scan(/\//))
            after_def = value_expected = false
            tokens << [:open, :regexp]
            state = :regexp
            string_delimiter = '/'
            kind = :delimiter

          elsif scan(/ @ #{IDENT} /ox)
            after_def = value_expected = false
            kind = :annotation

          elsif scan(/\//)
            after_def = false
            value_expected = true
            kind = :operator
          
          else
            getch
            kind = :error

          end

        when :string, :regexp, :multiline_string
          if scan(STRING_CONTENT_PATTERN[string_delimiter])
            kind = :content
            
          elsif match = scan(state == :multiline_string ? /'''|"""/ : /["'\/]/)
            tokens << [match, :delimiter]
            if state == :regexp
              # TODO: regexp modifiers? s, m, x, i?
              modifiers = scan(/[ix]+/)
              tokens << [modifiers, :modifier] if modifiers && !modifiers.empty?
            end
            state = :string if state == :multiline_string
            tokens << [:close, state]
            string_delimiter = nil
            after_def = value_expected = false
            state = :initial
            next
          
          elsif (state == :string || state == :multiline_string) &&
              (match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox))
            if string_delimiter[0] == ?' && !(match == "\\\\" || match == "\\'")
              kind = :content
            else
              kind = :char
            end
          elsif state == :regexp && scan(/ \\ (?: #{REGEXP_ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
            kind = :char
          
          elsif match = scan(/ \$ #{IDENT} /mox)
            tokens << [:open, :inline]
            tokens << ['$', :inline_delimiter]
            match = match[1..-1]
            tokens << [match, IDENT_KIND[match]]
            tokens << [:close, :inline]
            next
          elsif match = scan(/ \$ \{ /x)
            tokens << [:open, :inline]
            tokens << ['${', :inline_delimiter]
            inline_block_stack << [state, string_delimiter, inline_block_paren_depth]
            inline_block_paren_depth = 1
            state = :initial
            next
          
          elsif scan(/ \$ /mx)
            kind = :content
          
          elsif scan(/ \\. /mx)
            kind = :content
          
          elsif scan(/ \\ | \n /x)
            tokens << [:close, state]
            kind = :error
            after_def = value_expected = false
            state = :initial
          
          else
            raise_inspect "else case \" reached; %p not handled." % peek(1), tokens
          end

        else
          raise_inspect 'Unknown state', tokens

        end

        match ||= matched
        if $CODERAY_DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens
        end
        raise_inspect 'Empty token', tokens unless match
        
        last_token = match unless [:space, :comment, :doctype].include? kind
        
        tokens << [match, kind]

      end

      if [:multiline_string, :string, :regexp].include? state
        tokens << [:close, state]
      end

      tokens
    end

  end

end
end
