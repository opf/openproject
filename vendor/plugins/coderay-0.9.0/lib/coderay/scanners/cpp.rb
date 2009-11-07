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

      until eos?

        kind = nil
        match = nil
        
        case state

        when :initial

          if scan(/ \s+ | \\\n /x)
            kind = :space

          elsif scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
            kind = :comment

          elsif match = scan(/ \# \s* if \s* 0 /x)
            match << scan_until(/ ^\# (?:elif|else|endif) .*? $ | \z /xm) unless eos?
            kind = :comment

          elsif scan(/ [-+*=<>?:;,!&^|()\[\]{}~%]+ | \/=? | \.(?!\d) /x)
            kind = :operator

          elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
            kind = IDENT_KIND[match]
            if kind == :ident and check(/:(?!:)/)
              # FIXME: don't match a?b:c
              kind = :label
            elsif match == 'class'
              state = :class_name_expected
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

          elsif scan(/#\s*(\w*)/)
            kind = :preprocessor
            state = :include_expected if self[1] == 'include'

          elsif scan(/ L?' (?: [^\'\n\\] | \\ #{ESCAPE} )? '? /ox)
            kind = :char

          elsif scan(/0[xX][0-9A-Fa-f]+/)
            kind = :hex

          elsif scan(/(?:0[0-7]+)(?![89.eEfF])/)
            kind = :oct

          elsif scan(/(?:\d+)(?![.eEfF])L?L?/)
            kind = :integer

          elsif scan(/\d[fF]?|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
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
            next
          elsif scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
            kind = :char
          elsif scan(/ \\ | $ /x)
            tokens << [:close, :string]
            kind = :error
            state = :initial
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
        if $DEBUG and not kind
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
