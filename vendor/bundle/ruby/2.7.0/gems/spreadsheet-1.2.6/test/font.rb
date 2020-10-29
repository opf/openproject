#!/usr/bin/env ruby
# TestFont -- Spreadsheet -- 09.10.2008 -- hwyss@ywesee.com

$: << File.expand_path('../lib', File.dirname(__FILE__))

require 'test/unit'
require 'spreadsheet'

module Spreadsheet
  class TestFont < Test::Unit::TestCase
    def setup
      @font = Font.new 'Arial'
    end
    def test_italic
      assert_equal false, @font.italic
      @font.italic!
      assert_equal true, @font.italic
      @font.italic = nil
      assert_equal false, @font.italic
      @font.italic = 1
      assert_equal true, @font.italic
    end
    def test_encoding
      assert_equal :default, @font.encoding
      @font.encoding = :apple_roman
      assert_equal :apple_roman, @font.encoding
      @font.encoding = 'Chinese Simplified'
      assert_equal :chinese_simplified, @font.encoding
      assert_raises ArgumentError do @font.size = 'ascii' end
      assert_equal :chinese_simplified, @font.encoding
      @font.encoding = nil
      assert_equal :default, @font.encoding
    end
    def test_family
      assert_equal :none, @font.family
      @font.family = :roman
      assert_equal :roman, @font.family
      @font.family = 'Swiss'
      assert_equal :swiss, @font.family
      assert_raises ArgumentError do @font.size = :greek end
      assert_equal :swiss, @font.family
      @font.family = nil
      assert_equal :none, @font.family
    end
    def test_name
      assert_equal 'Arial', @font.name
      @font.name = 'Helvetica'
      assert_equal 'Helvetica', @font.name
    end
    def test_outline
      assert_equal false, @font.outline
      @font.outline!
      assert_equal true, @font.outline
      @font.outline = nil
      assert_equal false, @font.outline
      @font.outline = 1
      assert_equal true, @font.outline
    end
    def test_escapement
      assert_equal :normal, @font.escapement
      @font.escapement = :superscript
      assert_equal :superscript, @font.escapement
      @font.escapement = 'sub'
      assert_equal :subscript, @font.escapement
      assert_raises ArgumentError do @font.size = "upwards" end
      assert_equal :subscript, @font.escapement
      @font.escapement = nil
      assert_equal :normal, @font.escapement
    end
    def test_shadow
      assert_equal false, @font.shadow
      @font.shadow!
      assert_equal true, @font.shadow
      @font.shadow = nil
      assert_equal false, @font.shadow
      @font.shadow = 1
      assert_equal true, @font.shadow
    end
    def test_size
      assert_equal 10, @font.size
      @font.size = 12
      assert_equal 12, @font.size
      @font.size = 11.2
      assert_equal 11.2, @font.size
      assert_raises ArgumentError do @font.size = "123" end
    end
    def test_strikeout
      assert_equal false, @font.strikeout
      @font.strikeout!
      assert_equal true, @font.strikeout
      @font.strikeout = nil
      assert_equal false, @font.strikeout
      @font.strikeout = 1
      assert_equal true, @font.strikeout
    end
    def test_underline
      assert_equal :none, @font.underline
      @font.underline = :single
      assert_equal :single, @font.underline
      @font.underline = 'double accounting'
      assert_equal :double_accounting, @font.underline
      assert_raises ArgumentError do @font.size = :triple end
      assert_equal :double_accounting, @font.underline
      @font.underline = nil
      assert_equal :none, @font.underline
      @font.underline = true
      assert_equal :single, @font.underline
    end
    def test_weight
      assert_equal :normal, @font.weight
      @font.weight = :bold
      assert_equal :bold, @font.weight
      @font.weight = 100
      assert_equal 100, @font.weight
      assert_raises ArgumentError do @font.weight = Object.new end
      assert_equal 100, @font.weight
      @font.weight = 'bold'
      assert_equal :bold, @font.weight
      @font.weight = nil
      assert_equal :normal, @font.weight
    end
    def test_key
      expected = 'Arial_10_normal_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.name = 'Helvetica'
      expected = 'Helvetica_10_normal_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.size = 12
      expected = 'Helvetica_12_normal_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.weight = :bold
      expected = 'Helvetica_12_bold_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.italic!
      expected = 'Helvetica_12_bold_italic_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.strikeout!
      expected = 'Helvetica_12_bold_italic_strikeout_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.outline!
      expected = 'Helvetica_12_bold_italic_strikeout_outline_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.shadow!
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_normal_none_text_none_default'
      assert_equal expected, @font.key
      @font.escapement = :super
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_superscript_none_text_none_default'
      assert_equal expected, @font.key
      @font.underline = :double
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_superscript_double_text_none_default'
      assert_equal expected, @font.key
      @font.color = :blue
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_superscript_double_blue_none_default'
      assert_equal expected, @font.key
      @font.family = :swiss
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_superscript_double_blue_swiss_default'
      assert_equal expected, @font.key
      @font.encoding = :iso_latin1
      expected = 'Helvetica_12_bold_italic_strikeout_outline_shadow_superscript_double_blue_swiss_iso_latin1'
      assert_equal expected, @font.key
    end
  end
end
