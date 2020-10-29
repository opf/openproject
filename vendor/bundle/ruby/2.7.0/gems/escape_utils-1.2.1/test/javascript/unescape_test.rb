require File.expand_path("../../helper", __FILE__)

class JavascriptUnescapeTest < Minitest::Test
  def test_returns_empty_string_if_nil_passed
    assert_equal "", EscapeUtils.unescape_javascript(nil)
  end

  def test_quotes_and_newlines
    assert_equal %(This "thing" is really\n netos\n\n'), EscapeUtils.unescape_javascript(%(This \\"thing\\" is really\\n netos\\n\\n\\'))
  end

  def test_backslashes
    assert_equal %(backslash\\test), EscapeUtils.unescape_javascript(%(backslash\\\\test))
  end

  def test_closed_html_tags
    assert_equal %(dont </close> tags), EscapeUtils.unescape_javascript(%(dont <\\/close> tags))
  end

  def test_passes_through_standalone_backslash
    assert_equal "\\", EscapeUtils.unescape_javascript("\\")
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_utf8_or_ascii
      escaped = EscapeUtils.escape_javascript("dont </close> tags")

      escaped.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.unescape_javascript(escaped)
      end

      escaped.force_encoding 'UTF-8'
      begin
        EscapeUtils.unescape_javascript(escaped)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      escaped = EscapeUtils.escape_javascript("dont </close> tags")
      assert_equal Encoding.find('UTF-8'), EscapeUtils.unescape_javascript(escaped).encoding
    end
  end
end
