# encoding: UTF-8

require "test/unit"
require "stringex"
require File.join(File.expand_path(File.dirname(__FILE__)), "codepoint_test_helper.rb")
include CodepointTestHelper

class BasicLatinTest < Test::Unit::TestCase
  # This test suite is just regression test and debugging
  # to better transliterate the Basic Latin Unicode codepoints
  #
  # http://unicode.org/charts/
  # http://unicode.org/charts/PDF/U0000.pdf

  # NOTE: I can't figure out how to test control characters.
  # Get weird results trying to pack them to unicode.

  def test_spaces
    assert_equal_encoded " ", %w{0020 00a0}
    assert_equal_encoded "",  %w{200b 2060}
  end

  def test_exclamation_marks
    assert_equal_encoded "!", %w{0021 2762}
    assert_equal_encoded "!!", "203c"
    assert_equal_encoded "", "00a1"
    assert_equal_encoded "?!", "203d"
  end

  def test_quotation_marks
    assert_equal_encoded "\"", %w{0022 02ba 2033 3003}
  end

  def test_apostrophes
    assert_equal_encoded "'", %w{0027 02b9 02bc 02c8 2032}
  end

  def test_asterisks
    assert_equal_encoded "*", %w{002a 066d 204e 2217 26b9 2731}
  end

  def test_commas
    assert_equal_encoded ",", %w{002c 060c}
  end

  def test_periods
    assert_equal_encoded ".", %w{002e 06d4}
  end

  def test_hyphens
    assert_equal_encoded "-", %w{002d 2010 2011 2012 2212}
  end

  def test_endash
    assert_equal_encoded "--", %w{2013 2015}
  end

  def test_emdash
    assert_equal_encoded "---", %w{2014}
  end

  def test_dotleader
    assert_equal_encoded "..", %w{2025}
  end

  def test_ellipsis
    assert_equal_encoded "...", %w{2026}
  end

  def test_slashes
    assert_equal_encoded "/", %w{002f 2044 2215}
    assert_equal_encoded "\\", %w{005c 2216}
  end

  def test_colons
    assert_equal_encoded ":", %w{003a 2236}
  end

  def test_semicolons
    assert_equal_encoded ";", %w{003b 061b}
  end

  def test_less_thans
    assert_equal_encoded "<", %w{003c 2039 2329 27e8 3008}
  end

  def test_equals
    assert_equal_encoded "=", "003d"
  end

  def test_greater_thans
    assert_equal_encoded ">", %w{003e 203a 232a 27e9 3009}
  end

  def test_question_marks
    assert_equal_encoded "?", %w{003f 061f}
    assert_equal_encoded "", "00bf"
    assert_equal_encoded "?!", %w{203d 2048}
    assert_equal_encoded "!?", "2049"
  end

  def test_circumflexes
    assert_equal_encoded "^", %w{005e 2038 2303}
  end

  def test_underscores
    assert_equal_encoded "_", %w{005f 02cd 2017}
  end

  def test_grave_accents
    assert_equal_encoded "'", %w{02cb 2035}
    # Ascii grave accent should remain as ascii!
    assert_equal_encoded "`", "0060"
  end

  def test_bars
    assert_equal_encoded "|", %w{007c 2223 2758}
  end

  def test_tildes
    assert_equal_encoded "~", %w{007e 02dc 2053 223c ff5e}
  end

  def test_related_letters
    {
      "B" => "212c",
      "C" => %w{2102 212d},
      "E" => %w{2107 2130},
      "F" => "2131",
      "H" => %w{210b 210c 210d},
      "I" => %w{0130 0406 04c0 2110 2111 2160},
      "K" => "212a",
      "L" => "2112",
      "M" => "2133",
      "N" => "2115",
      "P" => "2119",
      "Q" => "211a",
      "R" => %w{211b 211c 211d},
      "Z" => %w{2124 2128}
    }.each do |expected, encode_mes|
      assert_equal_encoded expected, encode_mes
    end
  end
end
