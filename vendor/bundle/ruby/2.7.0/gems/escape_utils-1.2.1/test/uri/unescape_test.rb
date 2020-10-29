require File.expand_path("../../helper", __FILE__)

class UriUnescapeTest < Minitest::Test
  def test_doesnt_unescape_an_incomplete_escape
    assert_equal "%", EscapeUtils.unescape_uri("%")
    assert_equal "http%", EscapeUtils.unescape_uri("http%")
  end

  def test_uri_containing_tags
    assert_equal "fo<o>bar", EscapeUtils.unescape_uri("fo%3Co%3Ebar")
  end

  def test_uri_containing_spaces
    assert_equal "a space", EscapeUtils.unescape_uri("a%20space")
    assert_equal "a   sp ace ", EscapeUtils.unescape_uri("a%20%20%20sp%20ace%20")
    assert_equal "a+space", EscapeUtils.unescape_uri("a+space")
  end

  def test_uri_containing_mixed_characters
    assert_equal "q1!2\"'w$5&7/z8)?\\", EscapeUtils.unescape_uri("q1%212%22%27w%245%267%2Fz8%29%3F%5C")
    assert_equal "q1!2\"'w$5&7/z8)?\\", EscapeUtils.unescape_uri("q1!2%22'w$5&7/z8)?%5C")
  end

  def test_uri_containing_multibyte_charactes
    matz_name = "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8" # Matsumoto
    matz_name.force_encoding('UTF-8') if matz_name.respond_to?(:force_encoding)
    assert_equal matz_name, EscapeUtils.unescape_uri('%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8')
    matz_name_sep = "\xE3\x81\xBE\xE3\x81\xA4 \xE3\x82\x82\xE3\x81\xA8" # Matsu moto
    matz_name_sep.force_encoding('UTF-8') if matz_name_sep.respond_to?(:force_encoding)
    assert_equal matz_name_sep, EscapeUtils.unescape_uri('%E3%81%BE%E3%81%A4%20%E3%82%82%E3%81%A8')
  end

  def test_uri_containing_pluses
    assert_equal "a+plus", EscapeUtils.unescape_uri("a%2Bplus")
  end

  def test_escape_unescape_roundtrip
    (0..127).each do |index|
      char = index.chr
      assert_equal char, EscapeUtils.unescape_uri(EscapeUtils.escape_uri(char))
    end
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_valid_utf8_or_ascii
      escaped = EscapeUtils.escape_uri("fo<o>bar")

      escaped.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.unescape_uri(escaped)
      end

      escaped.force_encoding 'UTF-8'
      begin
        EscapeUtils.unescape_uri(escaped)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      escaped = EscapeUtils.escape_uri("a space")
      assert_equal Encoding.find('UTF-8'), EscapeUtils.unescape_uri(escaped).encoding
    end
  end
end
