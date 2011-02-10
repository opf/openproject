module CodeRay
module Scanners

  class CSS < Scanner

    register_for :css

    KINDS_NOT_LOC = [
      :comment,
      :class, :pseudo_class, :type,
      :constant, :directive,
      :key, :value, :operator, :color, :float,
      :error, :important,
    ]
    
    module RE
      Hex = /[0-9a-fA-F]/
      Unicode = /\\#{Hex}{1,6}(?:\r\n|\s)?/ # differs from standard because it allows uppercase hex too
      Escape = /#{Unicode}|\\[^\r\n\f0-9a-fA-F]/
      NMChar = /[-_a-zA-Z0-9]|#{Escape}/
      NMStart = /[_a-zA-Z]|#{Escape}/
      NL = /\r\n|\r|\n|\f/
      String1 = /"(?:[^\n\r\f\\"]|\\#{NL}|#{Escape})*"?/  # FIXME: buggy regexp
      String2 = /'(?:[^\n\r\f\\']|\\#{NL}|#{Escape})*'?/  # FIXME: buggy regexp
      String = /#{String1}|#{String2}/

      HexColor = /#(?:#{Hex}{6}|#{Hex}{3})/
      Color = /#{HexColor}/

      Num = /-?(?:[0-9]+|[0-9]*\.[0-9]+)/
      Name = /#{NMChar}+/
      Ident = /-?#{NMStart}#{NMChar}*/
      AtKeyword = /@#{Ident}/
      Percentage = /#{Num}%/

      reldimensions = %w[em ex px]
      absdimensions = %w[in cm mm pt pc]
      Unit = Regexp.union(*(reldimensions + absdimensions))

      Dimension = /#{Num}#{Unit}/

      Comment = %r! /\* (?: .*? \*/ | .* ) !mx
      Function = /(?:url|alpha)\((?:[^)\n\r\f]|\\\))*\)?/

      Id = /##{Name}/
      Class = /\.#{Name}/
      PseudoClass = /:#{Name}/
      AttributeSelector = /\[[^\]]*\]?/

    end

    def scan_tokens tokens, options
      
      value_expected = nil
      states = [:initial]

      until eos?

        kind = nil
        match = nil

        if scan(/\s+/)
          kind = :space

        elsif case states.last
          when :initial, :media
            if scan(/(?>#{RE::Ident})(?!\()|\*/ox)
              kind = :type
            elsif scan RE::Class
              kind = :class
            elsif scan RE::Id
              kind = :constant
            elsif scan RE::PseudoClass
              kind = :pseudo_class
            elsif match = scan(RE::AttributeSelector)
              # TODO: Improve highlighting inside of attribute selectors.
              tokens << [:open, :string]
              tokens << [match[0,1], :delimiter]
              tokens << [match[1..-2], :content] if match.size > 2
              tokens << [match[-1,1], :delimiter] if match[-1] == ?]
              tokens << [:close, :string]
              next
            elsif match = scan(/@media/)
              kind = :directive
              states.push :media_before_name
            end
          
          when :block
            if scan(/(?>#{RE::Ident})(?!\()/ox)
              if value_expected
                kind = :value
              else
                kind = :key
              end
            end

          when :media_before_name
            if scan RE::Ident
              kind = :type
              states[-1] = :media_after_name
            end
          
          when :media_after_name
            if scan(/\{/)
              kind = :operator
              states[-1] = :media
            end
          
          when :comment
            if scan(/(?:[^*\s]|\*(?!\/))+/)
              kind = :comment
            elsif scan(/\*\//)
              kind = :comment
              states.pop
            elsif scan(/\s+/)
              kind = :space
            end

          else
            raise_inspect 'Unknown state', tokens

          end

        elsif scan(/\/\*/)
          kind = :comment
          states.push :comment

        elsif scan(/\{/)
          value_expected = false
          kind = :operator
          states.push :block

        elsif scan(/\}/)
          value_expected = false
          if states.last == :block || states.last == :media
            kind = :operator
            states.pop
          else
            kind = :error
          end

        elsif match = scan(/#{RE::String}/o)
          tokens << [:open, :string]
          tokens << [match[0, 1], :delimiter]
          tokens << [match[1..-2], :content] if match.size > 2
          tokens << [match[-1, 1], :delimiter] if match.size >= 2
          tokens << [:close, :string]
          next

        elsif match = scan(/#{RE::Function}/o)
          tokens << [:open, :string]
          start = match[/^\w+\(/]
          tokens << [start, :delimiter]
          if match[-1] == ?)
            tokens << [match[start.size..-2], :content]
            tokens << [')', :delimiter]
          else
            tokens << [match[start.size..-1], :content]
          end
          tokens << [:close, :string]
          next

        elsif scan(/(?: #{RE::Dimension} | #{RE::Percentage} | #{RE::Num} )/ox)
          kind = :float

        elsif scan(/#{RE::Color}/o)
          kind = :color

        elsif scan(/! *important/)
          kind = :important

        elsif scan(/rgb\([^()\n]*\)?/)
          kind = :color

        elsif scan(/#{RE::AtKeyword}/o)
          kind = :directive

        elsif match = scan(/ [+>:;,.=()\/] /x)
          if match == ':'
            value_expected = true
          elsif match == ';'
            value_expected = false
          end
          kind = :operator

        else
          getch
          kind = :error

        end

        match ||= matched
        if $CODERAY_DEBUG and not kind
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
