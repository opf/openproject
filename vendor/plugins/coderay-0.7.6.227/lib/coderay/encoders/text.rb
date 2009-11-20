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
      @out = ''
      @sep = options[:separator]
    end

    def token text, kind
      @out << text + @sep if text.is_a? ::String
    end

    def finish options
      @out.chomp @sep
    end

  end

end
end
