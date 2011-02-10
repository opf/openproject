($:.unshift '../..'; require 'coderay') unless defined? CodeRay
module CodeRay
module Encoders
  
  class Filter < Encoder
    
    register_for :filter
    
  protected
    def setup options
      @out = Tokens.new
    end
    
    def text_token text, kind
      [text, kind] if include_text_token? text, kind
    end
    
    def include_text_token? text, kind
      true
    end
    
    def block_token action, kind
      [action, kind] if include_block_token? action, kind
    end
    
    def include_block_token? action, kind
      true
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

class FilterTest < Test::Unit::TestCase
  
  def test_creation
    assert CodeRay::Encoders::Filter < CodeRay::Encoders::Encoder
    filter = nil
    assert_nothing_raised do
      filter = CodeRay.encoder :filter
    end
    assert_kind_of CodeRay::Encoders::Encoder, filter
  end
  
  def test_filtering_text_tokens
    tokens = CodeRay::Tokens.new
    10.times do |i|
      tokens << [i.to_s, :index]
    end
    assert_equal tokens, CodeRay::Encoders::Filter.new.encode_tokens(tokens)
    assert_equal tokens, tokens.filter
  end
  
  def test_filtering_block_tokens
    tokens = CodeRay::Tokens.new
    10.times do |i|
      tokens << [:open, :index]
      tokens << [i.to_s, :content]
      tokens << [:close, :index]
    end
    assert_equal tokens, CodeRay::Encoders::Filter.new.encode_tokens(tokens)
    assert_equal tokens, tokens.filter
  end
  
end
