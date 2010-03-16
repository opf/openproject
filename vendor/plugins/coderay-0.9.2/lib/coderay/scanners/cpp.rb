module CodeRay
module Scanners

  class CPlusPlus < Scanner

    include Streamable
    
    register_for :cpp
    file_extension 'cpp'
    title 'C++'
    
    # http://www.cppreference.com/wiki/keywords/start
    RESERVED_WORDS = [
      'and', 'and_eq', 'asm', 'bitand', 'bitor', 'break',
      'case', 'catch', 'class', 'compl', 'const_cast',
      'continue', 'default', 'delete', 'do', 'dynamic_cast', 'else',
      'enum', 'export', 'for', 'goto', 'if', 'namespace', 'new',
      'not', 'not_eq', 'or', 'or_eq', 'reinterpret_cast', 'return',
      'sizeof', 'static_cast', 'struct', 'switch', 'template',
      'throw', 'try', 'typedef', 'typeid', 'typename', 'union',
      'while', 'xor', 'xor_eq'
    ]

    PREDEFINED_TYPES = [
      'bool', 'char', 'double', 'float', 'int', 'long',
      'short', 'signed', 'unsigned', 'wchar_t', 'string'
    ]
    PREDEFINED_CONSTANTS = [
      'false', 'true',
      'EOF', 'NULL',
    ]
    PREDEFINED_VARIABLES = [
      'this'
    ]
    DIRECTIVES = [
      'auto', 'const', 'explicit', 'extern', 'friend', 'inline', 'mutable', 'operator',
      'private', 'protected', 'public', 'register', 'static', 'using', 'virtual', 'void',
      'volatile'
    ]

    IDENT_KIND = WordList.new(:ident).
      add(RESERVED_WORDS, :reserved).
      add(PREDEFINED_TYPES, :pre_type).
      add(PREDEFINED_VARIABLES, :local_variable).
      add(DIRECTIVES, :directive).
      add(PREDEFINED_CONSTANTS, :pre_constant)

    ESCAPE = / [rbfntv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x

    def scan_tokens tokens, options

      state = :initial
      label_expected = true
      case_expected = false
      label_expected_before_preproc_line = nil
      in_preproc_line = false

      until eos?

        kind = nil
        match = nil
        
        case state

        when :initial

          if match = scan(/ \s+ | \\\n /x)
            if in_preproc_line && match != "\\\n" && match.index(?\n)
              in_preproc_line = false
              label_expected = label_expected_before_preproc_line
            end
            tokens << [match, :space]
            next

          elsif scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
            kind = :comment

          elsif match = scan(/ \# \s* if \s* 0 /x)
            match << scan_until(/ ^\# (?:elif|else|endif) .*? $ | \z /xm) unless eos?
            kind = :comment

          elsif match = scan(/ [-+*=<>?:;,!&^|()\[\]{}~%]+ | \/=? | \.(?!\d) /x)
            label_expected = match =~ /[;\{\}]/
            if case_expected
              label_expected = true if match == ':'
              case_expected = false
            end
            kind = :operator

          elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
            kind = IDENT_KIND[match]
            if kind == :ident && label_expected && !in_preproc_line && scan(/:(?!:)/)
              kind = :label
              match << matched
            else
              label_expected = false
              if kind == :reserved
                case match
                when 'class'
                  state = :class_name_expected
                when 'case', 'default'
                  case_expected = true
                end
              end
            end

          elsif scan(/\$/)
            kind = :ident
          
          elsif match = scan(/L?"/)
            tokens << [:open, :string]
            if match[0] == ?L
              tokens << ['L', :modifier]
              match = '"'
            end
            state = :string
            kind = :delimiter

          elsif scan(/#[ \t]*(\w*)/)
            kind = :preprocessor
            in_preproc_line = true
            label_expected_before_preproc_line = label_expected
            state = :include_expected if self[1] == 'include'

          elsif scan(/ L?' (?: [^\'\n\\] | \\ #{ESCAPE} )? '? /ox)
            label_expected = false
            kind = :char

          elsif scan(/0[xX][0-9A-Fa-f]+/)
            label_expected = false
            kind = :hex

          elsif scan(/(?:0[0-7]+)(?![89.eEfF])/)
            label_expected = false
            kind = :oct

          elsif scan(/(?:\d+)(?![.eEfF])L?L?/)
            label_expected = false
            kind = :integer

          elsif scan(/\d[fF]?|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
            label_expected = false
            kind = :float

          else
            getch
            kind = :error

          end

        when :string
          if scan(/[^\\"]+/)
            kind = :content
          elsif scan(/"/)
            tokens << ['"', :delimiter]
            tokens << [:close, :string]
            state = :initial
            label_expected = false
            next
          elsif scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
            kind = :char
          elsif scan(/ \\ | $ /x)
            tokens << [:close, :string]
            kind = :error
            state = :initial
            label_expected = false
          else
            raise_inspect "else case \" reached; %p not handled." % peek(1), tokens
          end

        when :include_expected
          if scan(/<[^>\n]+>?|"[^"\n\\]*(?:\\.[^"\n\\]*)*"?/)
            kind = :include
            state = :initial

          elsif match = scan(/\s+/)
            kind = :space
            state = :initial if match.index ?\n

          else
            state = :initial
            next

          end
        
        when :class_name_expected
          if scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
            kind = :class
            state = :initial

          elsif match = scan(/\s+/)
            kind = :space

          else
            getch
            kind = :error
            state = :initial

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

      if state == :string
        tokens << [:close, :string]
      end

      tokens
    end

  end

end
end
