module CodeRay
  
  # = Duo
  #
  # A Duo is a convenient way to use CodeRay. You just create a Duo,
  # giving it a lang (language of the input code) and a format (desired
  # output format), and call Duo#highlight with the code.
  # 
  # Duo makes it easy to re-use both scanner and encoder for a repetitive
  # task. It also provides a very easy interface syntax:
  # 
  #   require 'coderay'
  #   CodeRay::Duo[:python, :div].highlight 'import this'
  # 
  # Until you want to do uncommon things with CodeRay, I recommend to use
  # this method, since it takes care of everything.
  class Duo

    attr_accessor :lang, :format, :options
    
    # Create a new Duo, holding a lang and a format to highlight code.
    # 
    # simple:
    #   CodeRay::Duo[:ruby, :page].highlight 'bla 42'
    # 
    # streaming:
    #   CodeRay::Duo[:ruby, :page].highlight 'bar 23', :stream => true
    # 
    # with options:
    #   CodeRay::Duo[:ruby, :html, :hint => :debug].highlight '????::??'
    # 
    # alternative syntax without options:
    #   CodeRay::Duo[:ruby => :statistic].encode 'class << self; end'
    # 
    # alternative syntax with options:
    #   CodeRay::Duo[{ :ruby => :statistic }, :do => :something].encode 'abc'
    # 
    # The options are forwarded to scanner and encoder
    # (see CodeRay.get_scanner_options).
    def initialize lang = nil, format = nil, options = {}
      if format == nil and lang.is_a? Hash and lang.size == 1
        @lang = lang.keys.first
        @format = lang[@lang]
      else
        @lang = lang
        @format = format
      end
      @options = options
    end

    class << self
      # To allow calls like Duo[:ruby, :html].highlight.
      alias [] new
    end

    # The scanner of the duo. Only created once.
    def scanner
      @scanner ||= CodeRay.scanner @lang, CodeRay.get_scanner_options(@options)
    end
    
    # The encoder of the duo. Only created once.
    def encoder
      @encoder ||= CodeRay.encoder @format, @options
    end
    
    # Tokenize and highlight the code using +scanner+ and +encoder+.
    #
    # If the :stream option is set, the Duo will go into streaming mode,
    # saving memory for the cost of time.
    def encode code, options = { :stream => false }
      stream = options.delete :stream
      options = @options.merge options
      if stream
        encoder.encode_stream(code, @lang, options)
      else
        scanner.code = code
        encoder.encode_tokens(scanner.tokenize, options)
      end
    end
    alias highlight encode

  end

end

