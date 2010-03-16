($:.unshift '../..'; require 'coderay') unless defined? CodeRay
module CodeRay
module Encoders
  
  # Counts the LoC (Lines of Code). Returns an Integer >= 0.
  # 
  # Alias: :loc
  # 
  # Everything that is not comment, markup, doctype/shebang, or an empty line,
  # is considered to be code.
  # 
  # For example,
  # * HTML files not containing JavaScript have 0 LoC
  # * in a Java class without comments, LoC is the number of non-empty lines
  # 
  # A Scanner class should define the token kinds that are not code in the
  # KINDS_NOT_LOC constant, which defaults to [:comment, :doctype].
  class LinesOfCode < Encoder
    
    register_for :lines_of_code
    
    NON_EMPTY_LINE = /^\s*\S.*$/
    
    def compile tokens, options
      if scanner = tokens.scanner
        kinds_not_loc = scanner.class::KINDS_NOT_LOC
      else
        warn ArgumentError, 'Tokens have no scanner.' if $VERBOSE
        kinds_not_loc = CodeRay::Scanners::Scanner::KINDS_NOT_LOC
      end
      code = tokens.token_class_filter :exclude => kinds_not_loc
      @loc = code.text.scan(NON_EMPTY_LINE).size
    end
    
    def finish options
      @loc
    end
    
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

class LinesOfCodeTest < Test::Unit::TestCase
  
  def test_creation
    assert CodeRay::Encoders::LinesOfCode < CodeRay::Encoders::Encoder
    filter = nil
    assert_nothing_raised do
      filter = CodeRay.encoder :loc
    end
    assert_kind_of CodeRay::Encoders::LinesOfCode, filter
    assert_nothing_raised do
      filter = CodeRay.encoder :lines_of_code
    end
    assert_kind_of CodeRay::Encoders::LinesOfCode, filter
  end
  
  def test_lines_of_code
    tokens = CodeRay.scan <<-RUBY, :ruby
#!/usr/bin/env ruby

# a minimal Ruby program
puts "Hello world!"
    RUBY
    assert_equal 1, CodeRay::Encoders::LinesOfCode.new.encode_tokens(tokens)
    assert_equal 1, tokens.lines_of_code
    assert_equal 1, tokens.loc
  end
  
  def test_filtering_block_tokens
    tokens = CodeRay::Tokens.new
    tokens << ["Hello\n", :world]
    tokens << ["Hello\n", :space]
    tokens << ["Hello\n", :comment]
    assert_equal 2, CodeRay::Encoders::LinesOfCode.new.encode_tokens(tokens)
    assert_equal 2, tokens.lines_of_code
    assert_equal 2, tokens.loc
  end
  
end