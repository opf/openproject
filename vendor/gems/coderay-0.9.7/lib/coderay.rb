# = CodeRay Library
#
# CodeRay is a Ruby library for syntax highlighting.
#
# I try to make CodeRay easy to use and intuitive, but at the same time fully featured, complete,
# fast and efficient.
# 
# See README.
# 
# It consists mainly of
# * the main engine: CodeRay (Scanners::Scanner, Tokens/TokenStream, Encoders::Encoder), PluginHost
# * the scanners in CodeRay::Scanners
# * the encoders in CodeRay::Encoders
# 
# Here's a fancy graphic to light up this gray docu:
# 
# http://cycnus.de/raindark/coderay/scheme.png
# 
# == Documentation
#
# See CodeRay, Encoders, Scanners, Tokens.
#
# == Usage
#
# Remember you need RubyGems to use CodeRay, unless you have it in your load path. Run Ruby with
# -rubygems option if required.
#
# === Highlight Ruby code in a string as html
# 
#   require 'coderay'
#   print CodeRay.scan('puts "Hello, world!"', :ruby).html
#
#   # prints something like this:
#   puts <span class="s">&quot;Hello, world!&quot;</span>
# 
# 
# === Highlight C code from a file in a html div
# 
#   require 'coderay'
#   print CodeRay.scan(File.read('ruby.h'), :c).div
#   print CodeRay.scan_file('ruby.h').html.div
# 
# You can include this div in your page. The used CSS styles can be printed with
# 
#   % coderay_stylesheet
# 
# === Highlight without typing too much
# 
# If you are one of the hasty (or lazy, or extremely curious) people, just run this file:
# 
#   % ruby -rubygems /path/to/coderay/coderay.rb > example.html
# 
# and look at the file it created in your browser.
# 
# = CodeRay Module
#
# The CodeRay module provides convenience methods for the engine.
#
# * The +lang+ and +format+ arguments select Scanner and Encoder to use. These are
#   simply lower-case symbols, like <tt>:python</tt> or <tt>:html</tt>.
# * All methods take an optional hash as last parameter, +options+, that is send to
#   the Encoder / Scanner.
# * Input and language are always sorted in this order: +code+, +lang+.
#   (This is in alphabetical order, if you need a mnemonic ;)
# 
# You should be able to highlight everything you want just using these methods;
# so there is no need to dive into CodeRay's deep class hierarchy.
#
# The examples in the demo directory demonstrate common cases using this interface.
#  
# = Basic Access Ways
#
# Read this to get a general view what CodeRay provides.
# 
# == Scanning
#  
#  Scanning means analysing an input string, splitting it up into Tokens.
#  Each Token knows about what type it is: string, comment, class name, etc.
#
#  Each +lang+ (language) has its own Scanner; for example, <tt>:ruby</tt> code is
#  handled by CodeRay::Scanners::Ruby.
# 
# CodeRay.scan:: Scan a string in a given language into Tokens.
#                This is the most common method to use.
# CodeRay.scan_file:: Scan a file and guess the language using FileType.
# 
# The Tokens object you get from these methods can encode itself; see Tokens.
# 
# == Encoding
#
# Encoding means compiling Tokens into an output. This can be colored HTML or
# LaTeX, a textual statistic or just the number of non-whitespace tokens.
# 
# Each Encoder provides output in a specific +format+, so you select Encoders via
# formats like <tt>:html</tt> or <tt>:statistic</tt>.
# 
# CodeRay.encode:: Scan and encode a string in a given language.
# CodeRay.encode_tokens:: Encode the given tokens.
# CodeRay.encode_file:: Scan a file, guess the language using FileType and encode it.
#
# == Streaming
#
# Streaming saves RAM by running Scanner and Encoder in some sort of
# pipe mode; see TokenStream.
#
# CodeRay.scan_stream:: Scan in stream mode.
#
# == All-in-One Encoding
#
# CodeRay.encode:: Highlight a string with a given input and output format.
#
# == Instanciating
#
# You can use an Encoder instance to highlight multiple inputs. This way, the setup
# for this Encoder must only be done once.
#
# CodeRay.encoder:: Create an Encoder instance with format and options.
# CodeRay.scanner:: Create an Scanner instance for lang, with '' as default code.
#
# To make use of CodeRay.scanner, use CodeRay::Scanner::code=.
#
# The scanning methods provide more flexibility; we recommend to use these.
# 
# == Reusing Scanners and Encoders
# 
# If you want to re-use scanners and encoders (because that is faster), see
# CodeRay::Duo for the most convenient (and recommended) interface.
module CodeRay
  
  $CODERAY_DEBUG ||= false
  
  # Version: Major.Minor.Teeny[.Revision]
  # Major: 0 for pre-stable, 1 for stable
  # Minor: feature milestone
  # Teeny: development state, 0 for pre-release
  # Revision: Subversion Revision number (generated on rake gem:make)
  VERSION = '0.9.7'

  require 'coderay/tokens'
  require 'coderay/token_classes'
  require 'coderay/scanner'
  require 'coderay/encoder'
  require 'coderay/duo'
  require 'coderay/style'


  class << self

    # Scans the given +code+ (a String) with the Scanner for +lang+.
    #
    # This is a simple way to use CodeRay. Example:
    #  require 'coderay'
    #  page = CodeRay.scan("puts 'Hello, world!'", :ruby).html
    #
    # See also demo/demo_simple.
    def scan code, lang, options = {}, &block
      scanner = Scanners[lang].new code, options, &block
      scanner.tokenize
    end

    # Scans +filename+ (a path to a code file) with the Scanner for +lang+.
    #
    # If +lang+ is :auto or omitted, the CodeRay::FileType module is used to
    # determine it. If it cannot find out what type it is, it uses
    # CodeRay::Scanners::Plaintext.
    #
    # Calls CodeRay.scan.
    #
    # Example:
    #  require 'coderay'
    #  page = CodeRay.scan_file('some_c_code.c').html
    def scan_file filename, lang = :auto, options = {}, &block
      file = IO.read filename
      if lang == :auto
        require 'coderay/helpers/file_type'
        lang = FileType.fetch filename, :plaintext, true
      end
      scan file, lang, options = {}, &block
    end

    # Scan the +code+ (a string) with the scanner for +lang+.
    #
    # Calls scan.
    #
    # See CodeRay.scan.
    def scan_stream code, lang, options = {}, &block
      options[:stream] = true
      scan code, lang, options, &block
    end

    # Encode a string in Streaming mode.
    #
    # This starts scanning +code+ with the the Scanner for +lang+
    # while encodes the output with the Encoder for +format+.
    # +options+ will be passed to the Encoder.
    #
    # See CodeRay::Encoder.encode_stream
    def encode_stream code, lang, format, options = {}
      encoder(format, options).encode_stream code, lang, options
    end

    # Encode a string.
    #
    # This scans +code+ with the the Scanner for +lang+ and then
    # encodes it with the Encoder for +format+.
    # +options+ will be passed to the Encoder.
    #
    # See CodeRay::Encoder.encode
    def encode code, lang, format, options = {}
      encoder(format, options).encode code, lang, options
    end

    # Highlight a string into a HTML <div>.
    #
    # CSS styles use classes, so you have to include a stylesheet
    # in your output.
    #
    # See encode.
    def highlight code, lang, options = { :css => :class }, format = :div
      encode code, lang, format, options
    end

    # Encode pre-scanned Tokens.
    # Use this together with CodeRay.scan:
    #
    #  require 'coderay'
    #  
    #  # Highlight a short Ruby code example in a HTML span
    #  tokens = CodeRay.scan '1 + 2', :ruby
    #  puts CodeRay.encode_tokens(tokens, :span)
    #
    def encode_tokens tokens, format, options = {}
      encoder(format, options).encode_tokens tokens, options
    end

    # Encodes +filename+ (a path to a code file) with the Scanner for +lang+.
    #
    # See CodeRay.scan_file.
    # Notice that the second argument is the output +format+, not the input language.
    #
    # Example:
    #  require 'coderay'
    #  page = CodeRay.encode_file 'some_c_code.c', :html
    def encode_file filename, format, options = {}
      tokens = scan_file filename, :auto, get_scanner_options(options)
      encode_tokens tokens, format, options
    end

    # Highlight a file into a HTML <div>.
    #
    # CSS styles use classes, so you have to include a stylesheet
    # in your output.
    #
    # See encode.
    def highlight_file filename, options = { :css => :class }, format = :div
      encode_file filename, format, options
    end

    # Finds the Encoder class for +format+ and creates an instance, passing
    # +options+ to it.
    #
    # Example:
    #  require 'coderay'
    #  
    #  stats = CodeRay.encoder(:statistic)
    #  stats.encode("puts 17 + 4\n", :ruby)
    #  
    #  puts '%d out of %d tokens have the kind :integer.' % [
    #    stats.type_stats[:integer].count,
    #    stats.real_token_count
    #  ]
    #  #-> 2 out of 4 tokens have the kind :integer.
    def encoder format, options = {}
      Encoders[format].new options
    end

    # Finds the Scanner class for +lang+ and creates an instance, passing
    # +options+ to it.
    #
    # See Scanner.new.
    def scanner lang, options = {}
      Scanners[lang].new '', options
    end

    # Extract the options for the scanner from the +options+ hash.
    #
    # Returns an empty Hash if <tt>:scanner_options</tt> is not set.
    #
    # This is used if a method like CodeRay.encode has to provide options
    # for Encoder _and_ scanner.
    def get_scanner_options options
      options.fetch :scanner_options, {}
    end

  end

  # This Exception is raised when you try to stream with something that is not
  # capable of streaming.
  class NotStreamableError < Exception
    def initialize obj
      @obj = obj
    end

    def to_s
      '%s is not Streamable!' % @obj.class
    end
  end

  # A dummy module that is included by subclasses of CodeRay::Scanner an CodeRay::Encoder
  # to show that they are able to handle streams.
  module Streamable
  end

end

# Run a test script.
if $0 == __FILE__
  $stderr.print 'Press key to print demo.'; gets
  # Just use this file as an example of Ruby code.
  code = File.read(__FILE__)[/module CodeRay.*/m]
  print CodeRay.scan(code, :ruby).html
end
