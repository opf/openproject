module CodeRay
module Encoders

  class Text < Encoder

    include Streamable
    register_for :text

    FILE_EXTENSION = 'txt'

    DEFAULT_OPTIONS = {
      :separator => ''
    }

  protected
    def setup options
      super
      @sep = options[:separator]
    end

    def text_token text, kind
      text + @sep
    end

    def finish options
      super.chomp @sep
    end

  end

end
end
