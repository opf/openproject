module CodeRay

  # = Tokens
  #
  # The Tokens class represents a list of tokens returnd from
  # a Scanner.
  #
  # A token is not a special object, just a two-element Array
  # consisting of
  # * the _token_ _text_ (the original source of the token in a String) or
  #   a _token_ _action_ (:open, :close, :begin_line, :end_line)
  # * the _token_ _kind_ (a Symbol representing the type of the token)
  #
  # A token looks like this:
  #
  #   ['# It looks like this', :comment]
  #   ['3.1415926', :float]
  #   ['$^', :error]
  #
  # Some scanners also yield sub-tokens, represented by special
  # token actions, namely :open and :close.
  #
  # The Ruby scanner, for example, splits "a string" into:
  #
  #  [
  #   [:open, :string],
  #   ['"', :delimiter],
  #   ['a string', :content],
  #   ['"', :delimiter],
  #   [:close, :string]
  #  ]
  #
  # Tokens is the interface between Scanners and Encoders:
  # The input is split and saved into a Tokens object. The Encoder
  # then builds the output from this object.
  #
  # Thus, the syntax below becomes clear:
  #
  #   CodeRay.scan('price = 2.59', :ruby).html
  #   # the Tokens object is here -------^
  #
  # See how small it is? ;)
  #
  # Tokens gives you the power to handle pre-scanned code very easily:
  # You can convert it to a webpage, a YAML file, or dump it into a gzip'ed string
  # that you put in your DB.
  # 
  # It also allows you to generate tokens directly (without using a scanner),
  # to load them from a file, and still use any Encoder that CodeRay provides.
  #
  # Tokens' subclass TokenStream allows streaming to save memory.
  class Tokens < Array
    
    # The Scanner instance that created the tokens.
    attr_accessor :scanner
    
    # Whether the object is a TokenStream.
    #
    # Returns false.
    def stream?
      false
    end

    # Iterates over all tokens.
    #
    # If a filter is given, only tokens of that kind are yielded.
    def each kind_filter = nil, &block
      unless kind_filter
        super(&block)
      else
        super() do |text, kind|
          next unless kind == kind_filter
          yield text, kind
        end
      end
    end

    # Iterates over all text tokens.
    # Range tokens like [:open, :string] are left out.
    #
    # Example:
    #   tokens.each_text_token { |text, kind| text.replace html_escape(text) }
    def each_text_token
      each do |text, kind|
        next unless text.is_a? ::String
        yield text, kind
      end
    end

    # Encode the tokens using encoder.
    #
    # encoder can be
    # * a symbol like :html oder :statistic
    # * an Encoder class
    # * an Encoder object
    #
    # options are passed to the encoder.
    def encode encoder, options = {}
      unless encoder.is_a? Encoders::Encoder
        unless encoder.is_a? Class
          encoder_class = Encoders[encoder]
        end
        encoder = encoder_class.new options
      end
      encoder.encode_tokens self, options
    end


    # Turn into a string using Encoders::Text.
    #
    # +options+ are passed to the encoder if given.
    def to_s options = {}
      encode :text, options
    end

    # Redirects unknown methods to encoder calls.
    #
    # For example, if you call +tokens.html+, the HTML encoder
    # is used to highlight the tokens.
    def method_missing meth, options = {}
      Encoders[meth].new(options).encode_tokens self
    end

    # Returns the tokens compressed by joining consecutive
    # tokens of the same kind.
    #
    # This can not be undone, but should yield the same output
    # in most Encoders.  It basically makes the output smaller.
    #
    # Combined with dump, it saves space for the cost of time.
    #
    # If the scanner is written carefully, this is not required -
    # for example, consecutive //-comment lines could already be
    # joined in one comment token by the Scanner.
    def optimize
      last_kind = last_text = nil
      new = self.class.new
      for text, kind in self
        if text.is_a? String
          if kind == last_kind
            last_text << text
          else
            new << [last_text, last_kind] if last_kind
            last_text = text
            last_kind = kind
          end
        else
          new << [last_text, last_kind] if last_kind
          last_kind = last_text = nil
          new << [text, kind]
        end
      end
      new << [last_text, last_kind] if last_kind
      new
    end

    # Compact the object itself; see optimize.
    def optimize!
      replace optimize
    end
    
    # Ensure that all :open tokens have a correspondent :close one.
    #
    # TODO: Test this!
    def fix
      tokens = self.class.new
      # Check token nesting using a stack of kinds.
      opened = []
      for type, kind in self
        case type
        when :open
          opened.push [:close, kind]
        when :begin_line
          opened.push [:end_line, kind]
        when :close, :end_line
          expected = opened.pop
          if [type, kind] != expected
            # Unexpected :close; decide what to do based on the kind:
            # - token was never opened: delete the :close (just skip it)
            next unless opened.rindex expected
            # - token was opened earlier: also close tokens in between
            tokens << token until (token = opened.pop) == expected
          end
        end
        tokens << [type, kind]
      end
      # Close remaining opened tokens
      tokens << token while token = opened.pop
      tokens
    end
    
    def fix!
      replace fix
    end
    
    # TODO: Scanner#split_into_lines
    # 
    # Makes sure that:
    # - newlines are single tokens
    #   (which means all other token are single-line)
    # - there are no open tokens at the end the line
    #
    # This makes it simple for encoders that work line-oriented,
    # like HTML with list-style numeration.
    def split_into_lines
      raise NotImplementedError
    end

    def split_into_lines!
      replace split_into_lines
    end

    # Dumps the object into a String that can be saved
    # in files or databases.
    #
    # The dump is created with Marshal.dump;
    # In addition, it is gzipped using GZip.gzip.
    #
    # The returned String object includes Undumping
    # so it has an #undump method. See Tokens.load.
    #
    # You can configure the level of compression,
    # but the default value 7 should be what you want
    # in most cases as it is a good compromise between
    # speed and compression rate.
    #
    # See GZip module.
    def dump gzip_level = 7
      require 'coderay/helpers/gzip_simple'
      dump = Marshal.dump self
      dump = dump.gzip gzip_level
      dump.extend Undumping
    end

    # The total size of the tokens.
    # Should be equal to the input size before
    # scanning.
    def text_size
      size = 0
      each_text_token do |t, k|
        size + t.size
      end
      size
    end

    # Return all text tokens joined into a single string.
    def text
      map { |t, k| t if t.is_a? ::String }.join
    end

    # Include this module to give an object an #undump
    # method.
    #
    # The string returned by Tokens.dump includes Undumping.
    module Undumping
      # Calls Tokens.load with itself.
      def undump
        Tokens.load self
      end
    end

    # Undump the object using Marshal.load, then
    # unzip it using GZip.gunzip.
    #
    # The result is commonly a Tokens object, but
    # this is not guaranteed.
    def Tokens.load dump
      require 'coderay/helpers/gzip_simple'
      dump = dump.gunzip
      @dump = Marshal.load dump
    end

  end


  # = TokenStream
  #
  # The TokenStream class is a fake Array without elements.
  #
  # It redirects the method << to a block given at creation.
  #
  # This allows scanners and Encoders to use streaming (no
  # tokens are saved, the input is highlighted the same time it
  # is scanned) with the same code.
  #
  # See CodeRay.encode_stream and CodeRay.scan_stream
  class TokenStream < Tokens

    # Whether the object is a TokenStream.
    #
    # Returns true.
    def stream?
      true
    end

    # The Array is empty, but size counts the tokens given by <<.
    attr_reader :size

    # Creates a new TokenStream that calls +block+ whenever
    # its << method is called.
    #
    # Example:
    #
    #   require 'coderay'
    #   
    #   token_stream = CodeRay::TokenStream.new do |text, kind|
    #     puts 'kind: %s, text size: %d.' % [kind, text.size]
    #   end
    #   
    #   token_stream << ['/\d+/', :regexp]
    #   #-> kind: rexpexp, text size: 5.
    #
    def initialize &block
      raise ArgumentError, 'Block expected for streaming.' unless block
      @callback = block
      @size = 0
    end

    # Calls +block+ with +token+ and increments size.
    #
    # Returns self.
    def << token
      @callback.call(*token)
      @size += 1
      self
    end

    # This method is not implemented due to speed reasons. Use Tokens.
    def text_size
      raise NotImplementedError,
        'This method is not implemented due to speed reasons.'
    end

    # A TokenStream cannot be dumped. Use Tokens.
    def dump
      raise NotImplementedError, 'A TokenStream cannot be dumped.'
    end

    # A TokenStream cannot be optimized. Use Tokens.
    def optimize
      raise NotImplementedError, 'A TokenStream cannot be optimized.'
    end

  end

end

if $0 == __FILE__
  $VERBOSE = true
  $: << File.join(File.dirname(__FILE__), '..')
  eval DATA.read, nil, $0, __LINE__ + 4
end

__END__
require 'test/unit'

class TokensTest < Test::Unit::TestCase
  
  def test_creation
    assert CodeRay::Tokens < Array
    tokens = nil
    assert_nothing_raised do
      tokens = CodeRay::Tokens.new
    end
    assert_kind_of Array, tokens
  end
  
  def test_adding_tokens
    tokens = CodeRay::Tokens.new
    assert_nothing_raised do
      tokens << ['string', :type]
      tokens << ['()', :operator]
    end
    assert_equal tokens.size, 2
  end
  
  def test_dump_undump
    tokens = CodeRay::Tokens.new
    assert_nothing_raised do
      tokens << ['string', :type]
      tokens << ['()', :operator]
    end
    tokens2 = nil
    assert_nothing_raised do
      tokens2 = tokens.dump.undump
    end
    assert_equal tokens, tokens2
  end
  
end