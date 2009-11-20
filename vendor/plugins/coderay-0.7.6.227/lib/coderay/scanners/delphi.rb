module CodeRay
module Scanners
  
  class Delphi < Scanner

    register_for :delphi
    
    RESERVED_WORDS = [
      'and', 'array', 'as', 'at', 'asm', 'at', 'begin', 'case', 'class',
      'const', 'constructor', 'destructor', 'dispinterface', 'div', 'do',
      'downto', 'else', 'end', 'except', 'exports', 'file', 'finalization',
      'finally', 'for', 'function', 'goto', 'if', 'implementation', 'in',
      'inherited', 'initialization', 'inline', 'interface', 'is', 'label',
      'library', 'mod', 'nil', 'not', 'object', 'of', 'or', 'out', 'packed',
      'procedure', 'program', 'property', 'raise', 'record', 'repeat',
      'resourcestring', 'set', 'shl', 'shr', 'string', 'then', 'threadvar',
      'to', 'try', 'type', 'unit', 'until', 'uses', 'var', 'while', 'with',
      'xor', 'on'
    ]

    DIRECTIVES = [
      'absolute', 'abstract', 'assembler', 'at', 'automated', 'cdecl',
      'contains', 'deprecated', 'dispid', 'dynamic', 'export',
      'external', 'far', 'forward', 'implements', 'local', 
      'near', 'nodefault', 'on', 'overload', 'override',
      'package', 'pascal', 'platform', 'private', 'protected', 'public',
      'published', 'read', 'readonly', 'register', 'reintroduce',
      'requires', 'resident', 'safecall', 'stdcall', 'stored', 'varargs',
      'virtual', 'write', 'writeonly'
    ]

    IDENT_KIND = CaseIgnoringWordList.new(:ident, caching=true).
      add(RESERVED_WORDS, :reserved).
      add(DIRECTIVES, :directive)
    
    NAME_FOLLOWS = CaseIgnoringWordList.new(false, caching=true).
      add(%w(procedure function .))

  private
    def scan_tokens tokens, options

      state = :initial
      last_token = ''

      until eos?

        kind = nil
        match = nil

        if state == :initial
          
          if scan(/ \s+ /x)
            tokens << [matched, :space]
            next
            
          elsif scan(%r! \{ \$ [^}]* \}? | \(\* \$ (?: .*? \*\) | .* ) !mx)
            tokens << [matched, :preprocessor]
            next
            
          elsif scan(%r! // [^\n]* | \{ [^}]* \}? | \(\* (?: .*? \*\) | .* ) !mx)
            tokens << [matched, :comment]
            next
            
          elsif match = scan(/ <[>=]? | >=? | :=? | [-+=*\/;,@\^|\(\)\[\]] | \.\. /x)
            kind = :operator
          
          elsif match = scan(/\./)
            kind = :operator
            if last_token == 'end'
              tokens << [match, kind]
              next
            end
            
          elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
            kind = NAME_FOLLOWS[last_token] ? :ident : IDENT_KIND[match]
            
          elsif match = scan(/ ' ( [^\n']|'' ) (?:'|$) /x)
            tokens << [:open, :char]
            tokens << ["'", :delimiter]
            tokens << [self[1], :content]
            tokens << ["'", :delimiter]
            tokens << [:close, :char]
            next
            
          elsif match = scan(/ ' /x)
            tokens << [:open, :string]
            state = :string
            kind = :delimiter
            
          elsif scan(/ \# (?: \d+ | \$[0-9A-Fa-f]+ ) /x)
            kind = :char
            
          elsif scan(/ \$ [0-9A-Fa-f]+ /x)
            kind = :hex
            
          elsif scan(/ (?: \d+ ) (?![eE]|\.[^.]) /x)
            kind = :integer
            
          elsif scan(/ \d+ (?: \.\d+ (?: [eE][+-]? \d+ )? | [eE][+-]? \d+ ) /x)
            kind = :float

          else
            kind = :error
            getch

          end
          
        elsif state == :string
          if scan(/[^\n']+/)
            kind = :content
          elsif scan(/''/)
            kind = :char
          elsif scan(/'/)
            tokens << ["'", :delimiter]
            tokens << [:close, :string]
            state = :initial
            next
          elsif scan(/\n/)
            tokens << [:close, :string]
            kind = :error
            state = :initial
          else
            raise "else case \' reached; %p not handled." % peek(1), tokens
          end
          
        else
          raise 'else-case reached', tokens
          
        end
        
        match ||= matched
        if $DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens, state
        end
        raise_inspect 'Empty token', tokens unless match

        last_token = match
        tokens << [match, kind]
        
      end
      
      tokens
    end

  end

end
end
