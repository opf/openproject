($:.unshift '../..'; require 'coderay') unless defined? CodeRay
module CodeRay
module Encoders
  
  # = JSON Encoder
  class JSON < Encoder
    
    register_for :json
    FILE_EXTENSION = 'json'
    
  protected
    def setup options
      begin
        require 'json'
      rescue LoadError
        require 'rubygems'
        require 'json'
      end
      @out = []
    end
    
    def text_token text, kind
      { :type => 'text', :text => text, :kind => kind }
    end
    
    def block_token action, kind
      { :type => 'block', :action => action, :kind => kind }
    end
    
    def finish options
      @out.to_json
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
$:.delete '.'
require 'rubygems' if RUBY_VERSION < '1.9'

class JSONEncoderTest < Test::Unit::TestCase
  
  def test_json_output
    tokens = CodeRay.scan <<-RUBY, :ruby
puts "Hello world!"
    RUBY
    require 'json'
    assert_equal [
      {"type"=>"text", "text"=>"puts", "kind"=>"ident"},
      {"type"=>"text", "text"=>" ", "kind"=>"space"},
      {"type"=>"block", "action"=>"open", "kind"=>"string"},
      {"type"=>"text", "text"=>"\"", "kind"=>"delimiter"},
      {"type"=>"text", "text"=>"Hello world!", "kind"=>"content"},
      {"type"=>"text", "text"=>"\"", "kind"=>"delimiter"},
      {"type"=>"block", "action"=>"close", "kind"=>"string"},
      {"type"=>"text", "text"=>"\n", "kind"=>"space"}
    ], JSON.load(tokens.json)
  end
  
end