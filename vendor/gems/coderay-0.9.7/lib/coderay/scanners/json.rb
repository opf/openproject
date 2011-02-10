module CodeRay
module Scanners
  
  class JSON < Scanner
    
    include Streamable
    
    register_for :json
    file_extension 'json'
    
    KINDS_NOT_LOC = [
      :float, :char, :content, :delimiter,
      :error, :integer, :operator, :value,
    ]
    
    ESCAPE = / [bfnrt\\"\/] /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} /x
    
    def scan_tokens tokens, options
      
      state = :initial
      stack = []
      key_expected = false
      
      until eos?
        
        kind = nil
        match = nil
        
        case state
        
        when :initial
          if match = scan(/ \s+ | \\\n /x)
            tokens << [match, :space]
            next
          elsif match = scan(/ [:,\[{\]}] /x)
            kind = :operator
            case match
            when '{' then stack << :object; key_expected = true
            when '[' then stack << :array
            when ':' then key_expected = false
            when ',' then key_expected = true if stack.last == :object
            when '}', ']' then stack.pop  # no error recovery, but works for valid JSON
            end
          elsif match = scan(/ true | false | null /x)
            kind = :value
          elsif match = scan(/-?(?:0|[1-9]\d*)/)
            kind = :integer
            if scan(/\.\d+(?:[eE][-+]?\d+)?|[eE][-+]?\d+/)
              match << matched
              kind = :float
            end
          elsif match = scan(/"/)
            state = key_expected ? :key : :string
            tokens << [:open, state]
            kind = :delimiter
          else
            getch
            kind = :error
          end
          
        when :string, :key
          if scan(/[^\\"]+/)
            kind = :content
          elsif scan(/"/)
            tokens << ['"', :delimiter]
            tokens << [:close, state]
            state = :initial
            next
          elsif scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
            kind = :char
          elsif scan(/\\./m)
            kind = :content
          elsif scan(/ \\ | $ /x)
            tokens << [:close, state]
            kind = :error
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
      
      if [:string, :key].include? state
        tokens << [:close, state]
      end
      
      tokens
    end
    
  end
  
end
end
