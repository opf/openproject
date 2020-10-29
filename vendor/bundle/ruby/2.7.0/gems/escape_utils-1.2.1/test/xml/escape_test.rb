require File.expand_path("../../helper", __FILE__)

class XmlEscapeTest < Minitest::Test
  def test_basic_xml
    assert_equal "&lt;some_tag/&gt;", EscapeUtils.escape_xml("<some_tag/>")
  end

  def test_double_quotes
    assert_equal "&lt;some_tag some_attr=&quot;some value&quot;/&gt;", EscapeUtils.escape_xml("<some_tag some_attr=\"some value\"/>")
  end

  def test_single_quotes
    assert_equal "&lt;some_tag some_attr=&apos;some value&apos;/&gt;", EscapeUtils.escape_xml("<some_tag some_attr='some value'/>")
  end

  def test_ampersand
    assert_equal "&lt;b&gt;Bourbon &amp; Branch&lt;/b&gt;", EscapeUtils.escape_xml("<b>Bourbon & Branch</b>")
  end

  # See http://www.w3.org/TR/REC-xml/#charsets for details.
  VALID = [
    (0x9..0xA), 0xD,
    (0x20..0xD7FF),
    (0xE000..0xFFFD),
    (0x10000..0x10FFFF)
  ]

  REPLACEMENT_CHAR = "?".unpack('U*').first

  def test_invalid_characters
    VALID.each do |range|
      if range.kind_of? Range
        start = range.begin
        last = range.end
        last -= 1 if range.exclude_end?
      else
        start = last = range
      end
      input = [start.pred, start, last, last.next].pack('U*')
      expect = [REPLACEMENT_CHAR, start, last, REPLACEMENT_CHAR].pack('U*')
      assert_equal expect, EscapeUtils.escape_xml(input)
    end
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_utf8_or_ascii
      str = "<some_tag/>"

      str.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.escape_xml(str)
      end

      str.force_encoding 'UTF-8'
      begin
        EscapeUtils.escape_xml(str)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      str = "<some_tag/>"
      assert_equal Encoding.find('UTF-8'), EscapeUtils.escape_url(str).encoding
    end
  end
end
