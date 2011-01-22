module CodeRay

  # This module holds the Encoder class and its subclasses.
  # For example, the HTML encoder is named CodeRay::Encoders::HTML
  # can be found in coderay/encoders/html.
  #
  # Encoders also provides methods and constants for the register
  # mechanism and the [] method that returns the Encoder class
  # belonging to the given format.
  module Encoders
    extend PluginHost
    plugin_path File.dirname(__FILE__), 'encoders'

    # = Encoder
    #
    # The Encoder base class. Together with Scanner and
    # Tokens, it forms the highlighting triad.
    #
    # Encoder instances take a Tokens object and do something with it.
    #
    # The most common Encoder is surely the HTML encoder
    # (CodeRay::Encoders::HTML). It highlights the code in a colorful
    # html page.
    # If you want the highlighted code in a div or a span instead,
    # use its subclasses Div and Span.
    class Encoder
      extend Plugin
      plugin_host Encoders

      attr_reader :token_stream

      class << self

        # Returns if the Encoder can be used in streaming mode.
        def streamable?
          is_a? Streamable
        end

        # If FILE_EXTENSION isn't defined, this method returns the
        # downcase class name instead.
        def const_missing sym
          if sym == :FILE_EXTENSION
            plugin_id
          else
            super
          end
        end

      end

      # Subclasses are to store their default options in this constant.
      DEFAULT_OPTIONS = { :stream => false }

      # The options you gave the Encoder at creating.
      attr_accessor :options

      # Creates a new Encoder.
      # +options+ is saved and used for all encode operations, as long
      # as you don't overwrite it there by passing additional options.
      #
      # Encoder objects provide three encode methods:
      # - encode simply takes a +code+ string and a +lang+
      # - encode_tokens expects a +tokens+ object instead
      # - encode_stream is like encode, but uses streaming mode.
      #
      # Each method has an optional +options+ parameter. These are
      # added to the options you passed at creation.
      def initialize options = {}
        @options = self.class::DEFAULT_OPTIONS.merge options
        raise "I am only the basic Encoder class. I can't encode "\
          "anything. :( Use my subclasses." if self.class == Encoder
      end

      # Encode a Tokens object.
      def encode_tokens tokens, options = {}
        options = @options.merge options
        setup options
        compile tokens, options
        finish options
      end

      # Encode the given +code+ after tokenizing it using the Scanner
      # for +lang+.
      def encode code, lang, options = {}
        options = @options.merge options
        scanner_options = CodeRay.get_scanner_options(options)
        tokens = CodeRay.scan code, lang, scanner_options
        encode_tokens tokens, options
      end

      # You can use highlight instead of encode, if that seems
      # more clear to you.
      alias highlight encode

      # Encode the given +code+ using the Scanner for +lang+ in
      # streaming mode.
      def encode_stream code, lang, options = {}
        raise NotStreamableError, self unless kind_of? Streamable
        options = @options.merge options
        setup options
        scanner_options = CodeRay.get_scanner_options options
        @token_stream =
          CodeRay.scan_stream code, lang, scanner_options, &self
        finish options
      end

      # Behave like a proc. The token method is converted to a proc.
      def to_proc
        method(:token).to_proc
      end

      # Return the default file extension for outputs of this encoder.
      def file_extension
        self.class::FILE_EXTENSION
      end

    protected

      # Called with merged options before encoding starts.
      # Sets @out to an empty string.
      #
      # See the HTML Encoder for an example of option caching.
      def setup options
        @out = ''
      end

      # Called with +content+ and +kind+ of the currently scanned token.
      # For simple scanners, it's enougth to implement this method.
      #
      # By default, it calls text_token or block_token, depending on
      # whether +content+ is a String.
      def token content, kind
        encoded_token =
          if content.is_a? ::String
            text_token content, kind
          elsif content.is_a? ::Symbol
            block_token content, kind
          else
            raise 'Unknown token content type: %p' % [content]
          end
        append_encoded_token_to_output encoded_token
      end
      
      def append_encoded_token_to_output encoded_token
        @out << encoded_token if encoded_token && defined?(@out) && @out
      end
      
      # Called for each text token ([text, kind]), where text is a String.
      def text_token text, kind
      end
      
      # Called for each block (non-text) token ([action, kind]),
      # where +action+ is a Symbol.
      # 
      # Calls open_token, close_token, begin_line, and end_line according to
      # the value of +action+.
      def block_token action, kind
        case action
        when :open
          open_token kind
        when :close
          close_token kind
        when :begin_line
          begin_line kind
        when :end_line
          end_line kind
        else
          raise 'unknown block action: %p' % action
        end
      end
      
      # Called for each block token at the start of the block ([:open, kind]).
      def open_token kind
      end
      
      # Called for each block token end of the block ([:close, kind]).
      def close_token kind
      end
      
      # Called for each line token block at the start of the line ([:begin_line, kind]).
      def begin_line kind
      end
      
      # Called for each line token block at the end of the line ([:end_line, kind]).
      def end_line kind
      end

      # Called with merged options after encoding starts.
      # The return value is the result of encoding, typically @out.
      def finish options
        @out
      end

      # Do the encoding.
      #
      # The already created +tokens+ object must be used; it can be a
      # TokenStream or a Tokens object.
      if RUBY_VERSION >= '1.9'
        def compile tokens, options
          for text, kind in tokens
            token text, kind
          end
        end
      else
        def compile tokens, options
          tokens.each(&self)
        end
      end

    end

  end
end
