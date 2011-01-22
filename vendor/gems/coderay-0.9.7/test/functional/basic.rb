require 'test/unit'
require 'coderay'

class BasicTest < Test::Unit::TestCase
  
  def test_version
    assert_nothing_raised do
      assert_match(/\A\d\.\d\.\d\z/, CodeRay::VERSION)
    end
  end
  
  RUBY_TEST_CODE = 'puts "Hello, World!"'
  
  RUBY_TEST_TOKENS = [
    ['puts', :ident],
    [' ', :space],
    [:open, :string],
      ['"', :delimiter],
      ['Hello, World!', :content],
      ['"', :delimiter],
    [:close, :string]
  ]
  def test_simple_scan
    assert_nothing_raised do
      assert_equal RUBY_TEST_TOKENS, CodeRay.scan(RUBY_TEST_CODE, :ruby).to_ary
    end
  end
  
  RUBY_TEST_HTML = 'puts <span class="s"><span class="dl">&quot;</span>' + 
    '<span class="k">Hello, World!</span><span class="dl">&quot;</span></span>'
  def test_simple_highlight
    assert_nothing_raised do
      assert_equal RUBY_TEST_HTML, CodeRay.scan(RUBY_TEST_CODE, :ruby).html
    end
  end
  
  def test_duo
    assert_equal(RUBY_TEST_CODE,
      CodeRay::Duo[:plain, :plain].highlight(RUBY_TEST_CODE))
    assert_equal(RUBY_TEST_CODE,
      CodeRay::Duo[:plain => :plain].highlight(RUBY_TEST_CODE))
  end
  
  def test_duo_stream
    assert_equal(RUBY_TEST_CODE,
      CodeRay::Duo[:plain, :plain].highlight(RUBY_TEST_CODE, :stream => true))
  end
  
  def test_comment_filter
    assert_equal <<-EXPECTED, CodeRay.scan(<<-INPUT, :ruby).comment_filter.text
#!/usr/bin/env ruby

code

more code  
      EXPECTED
#!/usr/bin/env ruby
=begin
A multi-line comment.
=end
code
# A single-line comment.
more code  # and another comment, in-line.
      INPUT
  end
  
  def test_lines_of_code
    assert_equal 2, CodeRay.scan(<<-INPUT, :ruby).lines_of_code
#!/usr/bin/env ruby
=begin
A multi-line comment.
=end
code
# A single-line comment.
more code  # and another comment, in-line.
      INPUT
    rHTML = <<-RHTML
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
  <title><%= controller.controller_name.titleize %>: <%= controller.action_name %></title>
  <%= stylesheet_link_tag 'scaffold' %>
</head>
<body>

<p style="color: green"><%= flash[:notice] %></p>

<div id="main">
  <%= yield %>
</div>

</body>
</html>
      RHTML
    assert_equal 0, CodeRay.scan(rHTML, :html).lines_of_code
    assert_equal 0, CodeRay.scan(rHTML, :php).lines_of_code
    assert_equal 0, CodeRay.scan(rHTML, :yaml).lines_of_code
    assert_equal 4, CodeRay.scan(rHTML, :rhtml).lines_of_code
  end
  
  def test_rubygems_not_loaded
    assert_equal nil, defined? Gem
  end if ENV['check_rubygems'] && RUBY_VERSION < '1.9'
  
  def test_list_of_encoders
    assert_kind_of(Array, CodeRay::Encoders.list)
    assert CodeRay::Encoders.list.include?('count')
  end
  
  def test_list_of_scanners
    assert_kind_of(Array, CodeRay::Scanners.list)
    assert CodeRay::Scanners.list.include?('plaintext')
  end
  
  def test_scan_a_frozen_string
    CodeRay.scan RUBY_VERSION, :ruby
  end
  
end
