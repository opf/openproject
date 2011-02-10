($:.unshift '../..'; require 'coderay') unless defined? CodeRay
module CodeRay
module Encoders
  
  load :token_class_filter
  
  class CommentFilter < TokenClassFilter
    
    register_for :comment_filter
    
    DEFAULT_OPTIONS = superclass::DEFAULT_OPTIONS.merge \
      :exclude => [:comment]
    
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

class CommentFilterTest < Test::Unit::TestCase
  
  def test_filtering_comments
    tokens = CodeRay.scan <<-RUBY, :ruby
#!/usr/bin/env ruby
# a minimal Ruby program
puts "Hello world!"
    RUBY
    assert_equal <<-RUBY_FILTERED, tokens.comment_filter.text
#!/usr/bin/env ruby

puts "Hello world!"
    RUBY_FILTERED
  end
  
end