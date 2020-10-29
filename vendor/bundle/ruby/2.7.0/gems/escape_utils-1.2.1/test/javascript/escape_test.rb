require File.expand_path("../../helper", __FILE__)

class JavascriptEscapeTest < Minitest::Test
  def test_returns_empty_string_if_nil_passed
    assert_equal "", EscapeUtils.escape_javascript(nil)
  end

  def test_quotes_and_newlines
    assert_equal %(This \\"thing\\" is really\\n netos\\n\\n\\'), EscapeUtils.escape_javascript(%(This "thing" is really\n netos\r\n\n'))
  end

  def test_backslashes
    assert_equal %(backslash\\\\test), EscapeUtils.escape_javascript(%(backslash\\test))
  end

  def test_closed_html_tags
    assert_equal %(keep <open>, but dont <\\/close> tags), EscapeUtils.escape_javascript(%(keep <open>, but dont </close> tags))
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_utf8_or_ascii
      str = "dont </close> tags"

      str.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.escape_javascript(str)
      end

      str.force_encoding 'UTF-8'
      begin
        EscapeUtils.escape_javascript(str)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      str = "dont </close> tags"
      assert_equal Encoding.find('UTF-8'), EscapeUtils.escape_javascript(str).encoding
    end
  end
end
