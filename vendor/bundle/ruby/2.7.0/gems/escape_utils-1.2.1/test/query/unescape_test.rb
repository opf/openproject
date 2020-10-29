require File.expand_path("../../helper", __FILE__)

class QueryUnescapeTest < Minitest::Test
  def test_basic_url
    assert_equal "http://www.homerun.com/", EscapeUtils.unescape_url("http%3A%2F%2Fwww.homerun.com%2F")
  end

  def test_url_containing_tags
    assert_equal "fo<o>bar", EscapeUtils.unescape_url("fo%3Co%3Ebar")
  end

  def test_url_containing_spaces
    assert_equal "a space", EscapeUtils.unescape_url("a+space")
    assert_equal "a   sp ace ", EscapeUtils.unescape_url("a+++sp+ace+")
  end

  def test_url_containing_mixed_characters
    assert_equal "q1!2\"'w$5&7/z8)?\\", EscapeUtils.unescape_url("q1%212%22%27w%245%267%2Fz8%29%3F%5C")
  end

  def test_url_containing_multibyte_characters
    matz_name = "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8" # Matsumoto
    matz_name.force_encoding('UTF-8') if matz_name.respond_to?(:force_encoding)
    assert_equal matz_name, EscapeUtils.unescape_url('%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8')
    matz_name_sep = "\xE3\x81\xBE\xE3\x81\xA4 \xE3\x82\x82\xE3\x81\xA8" # Matsu moto
    matz_name_sep.force_encoding('UTF-8') if matz_name_sep.respond_to?(:force_encoding)
    assert_equal matz_name_sep, EscapeUtils.unescape_url('%E3%81%BE%E3%81%A4+%E3%82%82%E3%81%A8')
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_valid_utf8_or_ascii
      escaped = EscapeUtils.unescape_url("a+space")

      escaped.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.unescape_url(escaped)
      end

      escaped.force_encoding 'UTF-8'
      begin
        EscapeUtils.unescape_url(escaped)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      escaped = EscapeUtils.escape_url("a space")
      assert_equal Encoding.find('UTF-8'), EscapeUtils.unescape_url(escaped).encoding
    end
  end
end
