require File.expand_path("../../helper", __FILE__)
require 'uri'

class UriEscapeTest < Minitest::Test
  def test_uri_stdlib_compatibility
    (0..127).each do |i|
      c = i.chr
      assert_equal URI.escape(c), EscapeUtils.escape_uri(c)
    end
  end

  def test_uri_containing_tags
    assert_equal "fo%3Co%3Ebar", EscapeUtils.escape_uri("fo<o>bar")
  end

  def test_uri_containing_spaces
    assert_equal "a%20space", EscapeUtils.escape_uri("a space")
    assert_equal "a%20%20%20sp%20ace%20", EscapeUtils.escape_uri("a   sp ace ")
  end

  def test_multibyte_characters
    matz_name = "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8" # Matsumoto
    assert_equal '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8', EscapeUtils.escape_uri(matz_name)
    matz_name_sep = "\xE3\x81\xBE\xE3\x81\xA4 \xE3\x82\x82\xE3\x81\xA8" # Matsu moto
    assert_equal '%E3%81%BE%E3%81%A4%20%E3%82%82%E3%81%A8', EscapeUtils.escape_uri(matz_name_sep)
  end

  def test_uri_containing_pluses
    assert_equal "a+plus", EscapeUtils.escape_uri("a+plus")
  end

  def test_uri_containing_slashes
    assert_equal "a/slash", EscapeUtils.escape_uri("a/slash")
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_utf8_or_ascii
      str = "fo<o>bar"

      str.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.escape_uri(str)
      end

      str.force_encoding 'UTF-8'
      begin
        EscapeUtils.escape_uri(str)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      str = "fo<o>bar"
      assert_equal Encoding.find('UTF-8'), EscapeUtils.escape_uri(str).encoding
    end
  end
end
