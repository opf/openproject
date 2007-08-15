module CodeRay
module Scanners

  # = Debug Scanner
  class Debug < Scanner

    include Streamable
    register_for :debug

  protected
    def scan_tokens tokens, options

      opened_tokens = []

      until eos?

        kind = nil
        match = nil

          if scan(/\s+/)
            tokens << [matched, :space]
            next
            
          elsif scan(/ (\w+) \( ( [^\)\\]* ( \\. [^\)\\]* )* ) \) /x)
            kind = self[1].to_sym
            match = self[2].gsub(/\\(.)/, '\1')
            
          elsif scan(/ (\w+) < /x)
            kind = self[1].to_sym
            opened_tokens << kind
            match = :open
            
          elsif scan(/ > /x)
            kind = opened_tokens.pop
            match = :close
            
          else
            kind = :error
            getch

          end
                  
        match ||= matched
        if $DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens
        end
        raise_inspect 'Empty token', tokens unless match

        tokens << [match, kind]
        
      end
      
      tokens
    end

  end

end
end
