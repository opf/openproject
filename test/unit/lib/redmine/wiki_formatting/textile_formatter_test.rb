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

require File.dirname(__FILE__) + '/../../../../test_helper'

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
    to_test = {
      '*bold*'                => '<strong>bold</strong>',
      'before *bold*'         => 'before <strong>bold</strong>',
      '*bold* after'          => '<strong>bold</strong> after',
      '*two words*'           => '<strong>two words</strong>',
      '*two*words*'           => '<strong>two*words</strong>',
      '*two * words*'         => '<strong>two * words</strong>',
      '*two* *words*'         => '<strong>two</strong> <strong>words</strong>',
      '*(two)* *(words)*'     => '<strong>(two)</strong> <strong>(words)</strong>',
      # with class
      '*(foo)two words*'      => '<strong class="foo">two words</strong>',
    }
    to_test.each do |text, expected|
      assert_equal "<p>#{expected}</p>", @formatter.new(text).to_html
    end
  end
  
  def test_modifiers_combination
    MODIFIERS.each do |m1, tag1|
      MODIFIERS.each do |m2, tag2|
        next if m1 == m2
        text = "#{m2}#{m1}Phrase modifiers#{m1}#{m2}"
        html = "<p><#{tag2}><#{tag1}>Phrase modifiers</#{tag1}></#{tag2}></p>"
        assert_equal html, @formatter.new(text).to_html
      end
    end
  end
  
  def test_inline_code
    to_test = {
      'this is @some code@'      => 'this is <code>some code</code>',
      '@<Location /redmine>@'    => '<code>&lt;Location /redmine&gt;</code>',
    }
    to_test.each do |text, expected|
      assert_equal "<p>#{expected}</p>", @formatter.new(text).to_html
    end
  end
  
  def test_escaping
    to_test = {
      'this is a <script>'      => 'this is a &lt;script&gt;',
    }
    to_test.each do |text, expected|
      assert_equal "<p>#{expected}</p>", @formatter.new(text).to_html
    end
  end
end
