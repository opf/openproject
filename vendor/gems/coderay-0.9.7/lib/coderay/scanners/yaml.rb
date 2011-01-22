module CodeRay
module Scanners
  
  # YAML Scanner
  #
  # Based on the YAML scanner from Syntax by Jamis Buck.
  class YAML < Scanner
    
    register_for :yaml
    file_extension 'yml'
    
    KINDS_NOT_LOC = :all
    
    def scan_tokens tokens, options
      
      value_expected = nil
      state = :initial
      key_indent = indent = 0
      
      until eos?
        
        kind = nil
        match = nil
        key_indent = nil if bol?
        
        if match = scan(/ +[\t ]*/)
          kind = :space
          
        elsif match = scan(/\n+/)
          kind = :space
          state = :initial if match.index(?\n)
          
        elsif match = scan(/#.*/)
          kind = :comment
          
        elsif bol? and case
          when match = scan(/---|\.\.\./)
            tokens << [:open, :head]
            tokens << [match, :head]
            tokens << [:close, :head]
            next
          when match = scan(/%.*/)
            tokens << [match, :doctype]
            next
          end
        
        elsif state == :value and case
          when !check(/(?:"[^"]*")(?=: |:$)/) && scan(/"/)
            tokens << [:open, :string]
            tokens << [matched, :delimiter]
            tokens << [matched, :content] if scan(/ [^"\\]* (?: \\. [^"\\]* )* /mx)
            tokens << [matched, :delimiter] if scan(/"/)
            tokens << [:close, :string]
            next
          when match = scan(/[|>][-+]?/)
            tokens << [:open, :string]
            tokens << [match, :delimiter]
            string_indent = key_indent || column(pos - match.size - 1)
            tokens << [matched, :content] if scan(/(?:\n+ {#{string_indent + 1}}.*)+/)
            tokens << [:close, :string]
            next
          when match = scan(/(?![!"*&]).+?(?=$|\s+#)/)
            tokens << [match, :string]
            string_indent = key_indent || column(pos - match.size - 1)
            tokens << [matched, :string] if scan(/(?:\n+ {#{string_indent + 1}}.*)+/)
            next
          end
          
        elsif case
          when match = scan(/[-:](?= |$)/)
            state = :value if state == :colon && (match == ':' || match == '-')
            state = :value if state == :initial && match == '-'
            kind = :operator
          when match = scan(/[,{}\[\]]/)
            kind = :operator
          when state == :initial && match = scan(/[\w.() ]*\S(?=: |:$)/)
            kind = :key
            key_indent = column(pos - match.size - 1)
            # tokens << [key_indent.inspect, :debug]
            state = :colon
          when match = scan(/(?:"[^"\n]*"|'[^'\n]*')(?=: |:$)/)
            tokens << [:open, :key]
            tokens << [match[0,1], :delimiter]
            tokens << [match[1..-2], :content]
            tokens << [match[-1,1], :delimiter]
            tokens << [:close, :key]
            key_indent = column(pos - match.size - 1)
            # tokens << [key_indent.inspect, :debug]
            state = :colon
            next
          when scan(/(![\w\/]+)(:([\w:]+))?/)
            tokens << [self[1], :type]
            if self[2]
              tokens << [':', :operator]
              tokens << [self[3], :class]
            end
            next
          when scan(/&\S+/)
            kind = :variable
          when scan(/\*\w+/)
            kind = :global_variable
          when scan(/<</)
            kind = :class_variable
          when scan(/\d\d:\d\d:\d\d/)
            kind = :oct
          when scan(/\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d(\.\d+)? [-+]\d\d:\d\d/)
            kind = :oct
          when scan(/:\w+/)
            kind = :symbol
          when scan(/[^:\s]+(:(?! |$)[^:\s]*)* .*/)
            kind = :error
          when scan(/[^:\s]+(:(?! |$)[^:\s]*)*/)
            kind = :error
          end
          
        else
          getch
          kind = :error
          
        end
        
        match ||= matched
        
        if $CODERAY_DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens, state
        end
        raise_inspect 'Empty token', tokens, state unless match
        
        tokens << [match, kind]
        
      end
      
      tokens
    end
    
  end
  
end
end
