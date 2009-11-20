module CodeRay
  module Scanners
    class Java < Scanner
    
      register_for :java
    
      RESERVED_WORDS = %w(abstract assert break case catch class
      const continue default do else enum extends final finally for
      goto if implements import instanceof interface native new
      package private protected public return static strictfp super switch
      synchronized this throw throws transient try void volatile while)
    
      PREDEFINED_TYPES = %w(boolean byte char double float int long short)
    
      PREDEFINED_CONSTANTS = %w(true false null)
    
      IDENT_KIND = WordList.new(:ident).
        add(RESERVED_WORDS, :reserved).
        add(PREDEFINED_TYPES, :pre_type).
        add(PREDEFINED_CONSTANTS, :pre_constant)
    
      ESCAPE = / [rbfnrtv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
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
  
            elsif scan(/ [-+*\/=<>?:;,!&^|()\[\]{}~%]+ | \.(?!\d) /x)
              kind = :operator
  
            elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
              kind = IDENT_KIND[match]
              if kind == :ident and check(/:(?!:)/)
                match << scan(/:/)
                kind = :label
              end
  
            elsif match = scan(/L?"/)
              tokens << [:open, :string]
              if match[0] == ?L
                tokens << ['L', :modifier]
                match = '"'
              end
              state = :string
              kind = :delimiter
  
            elsif scan(%r! \@ .* !x)
              kind = :preprocessor
  
            elsif scan(/ L?' (?: [^\'\n\\] | \\ #{ESCAPE} )? '? /ox)
              kind = :char
  
            elsif scan(/0[xX][0-9A-Fa-f]+/)
              kind = :hex
  
            elsif scan(/(?:0[0-7]+)(?![89.eEfF])/)
              kind = :oct
  
            elsif scan(/(?:\d+)(?![.eEfF])/)
              kind = :integer
  
            elsif scan(/\d[fF]?|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
              kind = :float
  
            else
              getch
              kind = :error
  
            end
  
          when :string
            if scan(/[^\\\n"]+/)
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
