module CodeRay
module Scanners
  
  class Diff < Scanner
    
    register_for :diff
    title 'diff output'
    
    def scan_tokens tokens, options
      
      line_kind = nil
      state = :initial
      
      until eos?
        kind = match = nil
        
        if match = scan(/\n/)
          if line_kind
            tokens << [:end_line, line_kind]
            line_kind = nil
          end
          tokens << [match, :space]
          next
        end
        
        case state
        
        when :initial
          if match = scan(/--- |\+\+\+ |=+|_+/)
            tokens << [:begin_line, line_kind = :head]
            tokens << [match, :head]
            next unless match = scan(/.+/)
            kind = :plain
          elsif match = scan(/Index: |Property changes on: /)
            tokens << [:begin_line, line_kind = :head]
            tokens << [match, :head]
            next unless match = scan(/.+/)
            kind = :plain
          elsif match = scan(/Added: /)
            tokens << [:begin_line, line_kind = :head]
            tokens << [match, :head]
            next unless match = scan(/.+/)
            kind = :plain
            state = :added
          elsif match = scan(/\\ /)
            tokens << [:begin_line, line_kind = :change]
            tokens << [match, :change]
            next unless match = scan(/.+/)
            kind = :plain
          elsif scan(/(@@)((?>[^@\n]*))(@@)/)
            tokens << [:begin_line, line_kind = :change]
            tokens << [self[1], :change]
            tokens << [self[2], :plain]
            tokens << [self[3], :change]
            next unless match = scan(/.+/)
            kind = :plain
          elsif match = scan(/\+/)
            tokens << [:begin_line, line_kind = :insert]
            tokens << [match, :insert]
            next unless match = scan(/.+/)
            kind = :plain
          elsif match = scan(/-/)
            tokens << [:begin_line, line_kind = :delete]
            tokens << [match, :delete]
            next unless match = scan(/.+/)
            kind = :plain
          elsif scan(/ .*/)
            kind = :comment
          elsif scan(/.+/)
            tokens << [:begin_line, line_kind = :head]
            kind = :plain
          else
            raise_inspect 'else case rached'
          end
        
        when :added
          if match = scan(/   \+/)
            tokens << [:begin_line, line_kind = :insert]
            tokens << [match, :insert]
            next unless match = scan(/.+/)
            kind = :plain
          else
            state = :initial
            next
          end
        end
        
        match ||= matched
        if $CODERAY_DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens
        end
        raise_inspect 'Empty token', tokens unless match
        
        tokens << [match, kind]
      end
      
      tokens << [:end_line, line_kind] if line_kind
      tokens
    end
    
  end
  
end
end
