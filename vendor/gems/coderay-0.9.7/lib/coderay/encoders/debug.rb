module CodeRay
module Encoders

  # = Debug Encoder
  #
  # Fast encoder producing simple debug output.
  #
  # It is readable and diff-able and is used for testing.
  #
  # You cannot fully restore the tokens information from the
  # output, because consecutive :space tokens are merged.
  # Use Tokens#dump for caching purposes.
  class Debug < Encoder

    include Streamable
    register_for :debug

    FILE_EXTENSION = 'raydebug'

  protected
    def text_token text, kind
      if kind == :space
        text
      else
        text = text.gsub(/[)\\]/, '\\\\\0')  # escape ) and \
        "#{kind}(#{text})"
      end
    end

    def open_token kind
      "#{kind}<"
    end

    def close_token kind
      ">"
    end

    def begin_line kind
      "#{kind}["
    end

    def end_line kind
      "]"
    end

  end

end
end
