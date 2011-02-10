# Redmine - project management software
# Copyright (C) 2006-2010  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

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
  
  private
  
  def assert_html_output(to_test)
    to_test.each do |text, expected|
      assert_equal "<p>#{expected}</p>", @formatter.new(text).to_html, "Formatting the following text failed:\n===\n#{text}\n===\n"
    end
  end
end
