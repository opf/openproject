#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../../../../test_helper', __FILE__)

class Redmine::WikiFormatting::TextileFormatterTest < HelperTestCase

  def setup
    @formatter = Redmine::WikiFormatting::Textile::Formatter
  end

  MODIFIERS = {
    "*" => 'strong', # bold
    "_" => 'em',     # italic
    "+" => 'ins',    # underline
    "-" => 'del',    # deleted
    "^" => 'sup',    # superscript
    "~" => 'sub'     # subscript
  }

  def test_modifiers
    assert_html_output(
      '*bold*'                => '<strong>bold</strong>',
      'before *bold*'         => 'before <strong>bold</strong>',
      '*bold* after'          => '<strong>bold</strong> after',
      '*two words*'           => '<strong>two words</strong>',
      '*two*words*'           => '<strong>two*words</strong>',
      '*two * words*'         => '<strong>two * words</strong>',
      '*two* *words*'         => '<strong>two</strong> <strong>words</strong>',
      '*(two)* *(words)*'     => '<strong>(two)</strong> <strong>(words)</strong>',
      # with class
      '*(foo)two words*'      => '<strong class="foo">two words</strong>'
    )
  end

  def test_modifiers_combination
    MODIFIERS.each do |m1, tag1|
      MODIFIERS.each do |m2, tag2|
        next if m1 == m2
        text = "#{m2}#{m1}Phrase modifiers#{m1}#{m2}"
        html = "<#{tag2}><#{tag1}>Phrase modifiers</#{tag1}></#{tag2}>"
        assert_html_output text => html
      end
    end
  end

  def test_inline_code
    assert_html_output(
      'this is @some code@'      => 'this is <code>some code</code>',
      '@<Location /redmine>@'    => '<code>&lt;Location /redmine&gt;</code>'
    )
  end

  def test_escaping
    assert_html_output(
      'this is a <script>'      => 'this is a &lt;script&gt;'
    )
  end

  def test_use_of_backslashes_followed_by_numbers_in_headers
    assert_html_output({
      'h1. 2009\02\09'      => '<h1>2009\02\09</h1>'
    }, false)
  end

  def test_double_dashes_should_not_strikethrough
    assert_html_output(
      'double -- dashes -- test'  => 'double -- dashes -- test',
      'double -- *dashes* -- test'  => 'double -- <strong>dashes</strong> -- test'
    )
  end

  def test_acronyms
    assert_html_output(
      'this is an acronym: GPL(General Public License)' => 'this is an acronym: <acronym title="General Public License">GPL</acronym>',
      '2 letters JP(Jean-Philippe) acronym' => '2 letters <acronym title="Jean-Philippe">JP</acronym> acronym',
      'GPL(This is a double-quoted "title")' => '<acronym title="This is a double-quoted &quot;title&quot;">GPL</acronym>'
    )
  end

  def test_blockquote
    # orig raw text
    raw = <<-RAW
John said:
> Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.
> Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.
> * Donec odio lorem,
> * sagittis ac,
> * malesuada in,
> * adipiscing eu, dolor.
>
> >Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.
> Proin a tellus. Nam vel neque.

He's right.
RAW

    # expected html
    expected = <<-EXPECTED
<p>John said:</p>
<blockquote>
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Maecenas sed libero.<br />
Nullam commodo metus accumsan nulla. Curabitur lobortis dui id dolor.
<ul>
  <li>Donec odio lorem,</li>
  <li>sagittis ac,</li>
  <li>malesuada in,</li>
  <li>adipiscing eu, dolor.</li>
</ul>
<blockquote>
<p>Nulla varius pulvinar diam. Proin id arcu id lorem scelerisque condimentum. Proin vehicula turpis vitae lacus.</p>
</blockquote>
<p>Proin a tellus. Nam vel neque.</p>
</blockquote>
<p>He's right.</p>
EXPECTED

    assert_equal expected.gsub(%r{\s+}, ''), to_html(raw).gsub(%r{\s+}, '')
  end

  def test_table
    raw = <<-RAW
This is a table with empty cells:

|cell11|cell12||
|cell21||cell23|
|cell31|cell32|cell33|
RAW

    expected = <<-EXPECTED
<p>This is a table with empty cells:</p>

<table>
  <tr><td>cell11</td><td>cell12</td><td></td></tr>
  <tr><td>cell21</td><td></td><td>cell23</td></tr>
  <tr><td>cell31</td><td>cell32</td><td>cell33</td></tr>
</table>
EXPECTED

    assert_equal expected.gsub(%r{\s+}, ''), to_html(raw).gsub(%r{\s+}, '')
  end

  def test_table_with_line_breaks
    raw = <<-RAW
This is a table with line breaks:

|cell11
continued|cell12||
|-cell21-||cell23
cell23 line2
cell23 *line3*|
|cell31|cell32
cell32 line2|cell33|

RAW

    expected = <<-EXPECTED
<p>This is a table with line breaks:</p>

<table>
  <tr>
    <td>cell11<br />continued</td>
    <td>cell12</td>
    <td></td>
  </tr>
  <tr>
    <td><del>cell21</del></td>
    <td></td>
    <td>cell23<br/>cell23 line2<br/>cell23 <strong>line3</strong></td>
  </tr>
  <tr>
    <td>cell31</td>
    <td>cell32<br/>cell32 line2</td>
    <td>cell33</td>
  </tr>
</table>
EXPECTED

    assert_equal expected.gsub(%r{\s+}, ''), to_html(raw).gsub(%r{\s+}, '')
  end

  def test_textile_should_not_mangle_brackets
    assert_equal '<p>[msg1][msg2]</p>', to_html('[msg1][msg2]')
  end

  def test_textile_should_escape_image_urls
    # this is onclick="alert('XSS');" in encoded form
    raw = '!/images/comment.png"onclick=&#x61;&#x6c;&#x65;&#x72;&#x74;&#x28;&#x27;&#x58;&#x53;&#x53;&#x27;&#x29;;&#x22;!'
    expected = '<p><img src="/images/comment.png&quot;onclick=&amp;#x61;&amp;#x6c;&amp;#x65;&amp;#x72;&amp;#x74;&amp;#x28;&amp;#x27;&amp;#x58;&amp;#x53;&amp;#x53;&amp;#x27;&amp;#x29;;&amp;#x22;" alt="" /></p>'

    assert_equal expected.gsub(%r{\s+}, ''), to_html(raw).gsub(%r{\s+}, '')
  end

  private

  def assert_html_output(to_test, expect_paragraph = true)
    to_test.each do |text, expected|
      assert_equal(( expect_paragraph ? "<p>#{expected}</p>" : expected ), @formatter.new(text).to_html, "Formatting the following text failed:\n===\n#{text}\n===\n")
    end
  end

  def to_html(text)
    @formatter.new(text).to_html
  end
end
