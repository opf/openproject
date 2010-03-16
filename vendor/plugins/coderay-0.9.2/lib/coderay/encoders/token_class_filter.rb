($:.unshift '../..'; require 'coderay') unless defined? CodeRay
module CodeRay
module Encoders
  
  load :filter
  
  class TokenClassFilter < Filter

    include Streamable
    register_for :token_class_filter

    DEFAULT_OPTIONS = {
      :exclude => [],
      :include => :all
    }

  protected
    def setup options
      super
      @exclude = options[:exclude]
      @exclude = Array(@exclude) unless @exclude == :all
      @include = options[:include]
      @include = Array(@include) unless @include == :all
    end
    
    def include_text_token? text, kind
       (@include == :all || @include.include?(kind)) &&
      !(@exclude == :all || @exclude.include?(kind))
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

class TokenClassFilterTest < Test::Unit::TestCase
  
  def test_creation
    assert CodeRay::Encoders::TokenClassFilter < CodeRay::Encoders::Encoder
    assert CodeRay::Encoders::TokenClassFilter < CodeRay::Encoders::Filter
    filter = nil
    assert_nothing_raised do
      filter = CodeRay.encoder :token_class_filter
    end
    assert_instance_of CodeRay::Encoders::TokenClassFilter, filter
  end
  
  def test_filtering_text_tokens
    tokens = CodeRay::Tokens.new
    for i in 1..10
      tokens << [i.to_s, :index]
      tokens << [' ', :space] if i < 10
    end
    assert_equal 10, CodeRay::Encoders::TokenClassFilter.new.encode_tokens(tokens, :exclude => :space).size
    assert_equal 10, tokens.token_class_filter(:exclude => :space).size
    assert_equal 9, CodeRay::Encoders::TokenClassFilter.new.encode_tokens(tokens, :include => :space).size
    assert_equal 9, tokens.token_class_filter(:include => :space).size
    assert_equal 0, CodeRay::Encoders::TokenClassFilter.new.encode_tokens(tokens, :exclude => :all).size
    assert_equal 0, tokens.token_class_filter(:exclude => :all).size
  end
  
  def test_filtering_block_tokens
    tokens = CodeRay::Tokens.new
    10.times do |i|
      tokens << [:open, :index]
      tokens << [i.to_s, :content]
      tokens << [:close, :index]
    end
    assert_equal 20, CodeRay::Encoders::TokenClassFilter.new.encode_tokens(tokens, :include => :blubb).size
    assert_equal 20, tokens.token_class_filter(:include => :blubb).size
    assert_equal 30, CodeRay::Encoders::TokenClassFilter.new.encode_tokens(tokens, :exclude => :index).size
    assert_equal 30, tokens.token_class_filter(:exclude => :index).size
  end
  
end
