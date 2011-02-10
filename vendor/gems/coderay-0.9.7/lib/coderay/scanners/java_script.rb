module CodeRay
module Scanners

  class JavaScript < Scanner

    include Streamable

    register_for :java_script
    file_extension 'js'

    # The actual JavaScript keywords.
    KEYWORDS = %w[
      break case catch continue default delete do else
      finally for function if in instanceof new
      return switch throw try typeof var void while with
    ]
    PREDEFINED_CONSTANTS = %w[
      false null true undefined
    ]
    
    MAGIC_VARIABLES = %w[ this arguments ]  # arguments was introduced in JavaScript 1.4
    
    KEYWORDS_EXPECTING_VALUE = WordList.new.add %w[
      case delete in instanceof new return throw typeof with
    ]
    
    # Reserved for future use.
    RESERVED_WORDS = %w[
      abstract boolean byte char class debugger double enum export extends
      final float goto implements import int interface long native package
      private protected public short static super synchronized throws transient
      volatile
    ]
    
    IDENT_KIND = WordList.new(:ident).
      add(RESERVED_WORDS, :reserved).
      add(PREDEFINED_CONSTANTS, :pre_constant).
      add(MAGIC_VARIABLES, :local_variable).
      add(KEYWORDS, :keyword)

    ESCAPE = / [bfnrtv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x
    REGEXP_ESCAPE =  / [bBdDsSwW] /x
    STRING_CONTENT_PATTERN = {
      "'" => /[^\\']+/,
      '"' => /[^\\"]+/,
      '/' => /[^\\\/]+/,
    }
    KEY_CHECK_PATTERN = {
      "'" => / (?> [^\\']* (?: \\. [^\\']* )* ) ' \s* : /mx,
      '"' => / (?> [^\\"]* (?: \\. [^\\"]* )* ) " \s* : /mx,
    }

    def scan_tokens tokens, options

      state = :initial
      string_delimiter = nil
      value_expected = true
      key_expected = false
      function_expected = false

      until eos?

        kind = nil
        match = nil
        
        case state

        when :initial

          if match = scan(/ \s+ | \\\n /x)
            value_expected = true if !value_expected && match.index(?\n)
            tokens << [match, :space]
            next

          elsif scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
            value_expected = true
            kind = :comment

          elsif check(/\.?\d/)
            key_expected = value_expected = false
            if scan(/0[xX][0-9A-Fa-f]+/)
              kind = :hex
            elsif scan(/(?>0[0-7]+)(?![89.eEfF])/)
              kind = :oct
            elsif scan(/\d+[fF]|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
              kind = :float
            elsif scan(/\d+/)
              kind = :integer
            end
          
          elsif value_expected && match = scan(/<([[:alpha:]]\w*) (?: [^\/>]*\/> | .*?<\/\1>)/xim)
            # FIXME: scan over nested tags
            xml_scanner.tokenize match
            value_expected = false
            next
            
          elsif match = scan(/ [-+*=<>?:;,!&^|(\[{~%]+ | \.(?!\d) /x)
            value_expected = true
            last_operator = match[-1]
            key_expected = (last_operator == ?{) || (last_operator == ?,)
            function_expected = false
            kind = :operator

          elsif scan(/ [)\]}]+ /x)
            function_expected = key_expected = value_expected = false
            kind = :operator

          elsif match = scan(/ [$a-zA-Z_][A-Za-z_0-9$]* /x)
            kind = IDENT_KIND[match]
            value_expected = (kind == :keyword) && KEYWORDS_EXPECTING_VALUE[match]
            # TODO: labels
            if kind == :ident
              if match.index(?$)  # $ allowed inside an identifier
                kind = :predefined
              elsif function_expected
                kind = :function
              elsif check(/\s*[=:]\s*function\b/)
                kind = :function
              elsif key_expected && check(/\s*:/)
                kind = :key
              end
            end
            function_expected = (kind == :keyword) && (match == 'function')
            key_expected = false
          
          elsif match = scan(/["']/)
            if key_expected && check(KEY_CHECK_PATTERN[match])
              state = :key
            else
              state = :string
            end
            tokens << [:open, state]
            string_delimiter = match
            kind = :delimiter

          elsif value_expected && (match = scan(/\/(?=\S)/))
            tokens << [:open, :regexp]
            state = :regexp
            string_delimiter = '/'
            kind = :delimiter

          elsif scan(/ \/ /x)
            value_expected = true
            key_expected = false
            kind = :operator

          else
            getch
            kind = :error

          end

        when :string, :regexp, :key
          if scan(STRING_CONTENT_PATTERN[string_delimiter])
            kind = :content
          elsif match = scan(/["'\/]/)
            tokens << [match, :delimiter]
            if state == :regexp
              modifiers = scan(/[gim]+/)
              tokens << [modifiers, :modifier] if modifiers && !modifiers.empty?
            end
            tokens << [:close, state]
            string_delimiter = nil
            key_expected = value_expected = false
            state = :initial
            next
          elsif state != :regexp && (match = scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox))
            if string_delimiter == "'" && !(match == "\\\\" || match == "\\'")
              kind = :content
            else
              kind = :char
            end
          elsif state == :regexp && scan(/ \\ (?: #{ESCAPE} | #{REGEXP_ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
            kind = :char
          elsif scan(/\\./m)
            kind = :content
          elsif scan(/ \\ | $ /x)
            tokens << [:close, state]
            kind = :error
            key_expected = value_expected = false
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
        
        tokens << [match, kind]

      end

      if [:string, :regexp].include? state
        tokens << [:close, state]
      end

      tokens
    end

  protected

    def reset_instance
      super
      @xml_scanner.reset if defined? @xml_scanner
    end

    def xml_scanner
      @xml_scanner ||= CodeRay.scanner :xml, :tokens => @tokens, :keep_tokens => true, :keep_state => false
    end

  end
  
end
end
