module CodeRay
module Scanners

  # HTML Scanner
  class HTML < Scanner

    include Streamable
    register_for :html
    
    KINDS_NOT_LOC = [
      :comment, :doctype, :preprocessor,
      :tag, :attribute_name, :operator,
      :attribute_value, :delimiter, :content,
      :plain, :entity, :error
    ]

    ATTR_NAME = /[\w.:-]+/
    ATTR_VALUE_UNQUOTED = ATTR_NAME
    TAG_END = /\/?>/
    HEX = /[0-9a-fA-F]/
    ENTITY = /
      &
      (?:
        \w+
      |
        \#
        (?:
          \d+
        |
          x#{HEX}+
        )
      )
      ;
    /ox

    PLAIN_STRING_CONTENT = {
      "'" => /[^&'>\n]+/,
      '"' => /[^&">\n]+/,
    }

    def reset
      super
      @state = :initial
    end

  private
    def setup
      @state = :initial
      @plain_string_content = nil
    end

    def scan_tokens tokens, options

      state = @state
      plain_string_content = @plain_string_content

      until eos?

        kind = nil
        match = nil

        if scan(/\s+/m)
          kind = :space

        else

          case state

          when :initial
            if scan(/<!--.*?-->/m)
              kind = :comment
            elsif scan(/<!DOCTYPE.*?>/m)
              kind = :doctype
            elsif scan(/<\?xml.*?\?>/m)
              kind = :preprocessor
            elsif scan(/<\?.*?\?>|<%.*?%>/m)
              kind = :comment
            elsif scan(/<\/[-\w.:]*>/m)
              kind = :tag
            elsif match = scan(/<[-\w.:]+>?/m)
              kind = :tag
              state = :attribute unless match[-1] == ?>
            elsif scan(/[^<>&]+/)
              kind = :plain
            elsif scan(/#{ENTITY}/ox)
              kind = :entity
            elsif scan(/[<>&]/)
              kind = :error
            else
              raise_inspect '[BUG] else-case reached with state %p' % [state], tokens
            end

          when :attribute
            if scan(/#{TAG_END}/)
              kind = :tag
              state = :initial
            elsif scan(/#{ATTR_NAME}/o)
              kind = :attribute_name
              state = :attribute_equal
            else
              kind = :error
              getch
            end

          when :attribute_equal
            if scan(/=/)
              kind = :operator
              state = :attribute_value
            elsif scan(/#{ATTR_NAME}/o)
              kind = :attribute_name
            elsif scan(/#{TAG_END}/o)
              kind = :tag
              state = :initial
            elsif scan(/./)
              kind = :error
              state = :attribute
            end

          when :attribute_value
            if scan(/#{ATTR_VALUE_UNQUOTED}/o)
              kind = :attribute_value
              state = :attribute
            elsif match = scan(/["']/)
              tokens << [:open, :string]
              state = :attribute_value_string
              plain_string_content = PLAIN_STRING_CONTENT[match]
              kind = :delimiter
            elsif scan(/#{TAG_END}/o)
              kind = :tag
              state = :initial
            else
              kind = :error
              getch
            end

          when :attribute_value_string
            if scan(plain_string_content)
              kind = :content
            elsif scan(/['"]/)
              tokens << [matched, :delimiter]
              tokens << [:close, :string]
              state = :attribute
              next
            elsif scan(/#{ENTITY}/ox)
              kind = :entity
            elsif scan(/&/)
              kind = :content
            elsif scan(/[\n>]/)
              tokens << [:close, :string]
              kind = :error
              state = :initial
            end

          else
            raise_inspect 'Unknown state: %p' % [state], tokens

          end

        end

        match ||= matched
        if $CODERAY_DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens, state
        end
        raise_inspect 'Empty token', tokens unless match

        tokens << [match, kind]
      end

      if options[:keep_state]
        @state = state
        @plain_string_content = plain_string_content
      end

      tokens
    end

  end

end
end
