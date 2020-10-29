require File.expand_path("../../helper", __FILE__)
require 'cgi'

class UriComponentEscapeTest < Minitest::Test
  def test_basic_url
    assert_equal "http%3A%2F%2Fwww.homerun.com%2F", EscapeUtils.escape_uri_component("http://www.homerun.com/")
  end

  def test_cgi_equivalence
    (0..127).each do |i|
      c = i.chr
      # Escaping URI path components should match CGI parameter escaping, except
      # spaces should be escaped as "%20" instead of "+"
      assert_equal CGI.escape(c).sub("+", "%20"), EscapeUtils.escape_uri_component(c)
    end
  end

  def test_uri_component_containing_tags
    assert_equal "fo%3Co%3Ebar", EscapeUtils.escape_uri_component("fo<o>bar")
  end

  def test_uri_component_containing_tags_containing_spaces
    assert_equal "a%20space", EscapeUtils.escape_uri_component("a space")
    assert_equal "a%20%20%20sp%20ace%20", EscapeUtils.escape_uri_component("a   sp ace ")
  end

  def test_uri_component_containing_mixed_characters
    assert_equal "q1%212%22%27w%245%267%2Fz8%29%3F%5C", EscapeUtils.escape_uri_component("q1!2\"'w$5&7/z8)?\\")
  end

  def test_multibyte_characters
    matz_name = "\xE3\x81\xBE\xE3\x81\xA4\xE3\x82\x82\xE3\x81\xA8" # Matsumoto
    assert_equal '%E3%81%BE%E3%81%A4%E3%82%82%E3%81%A8', EscapeUtils.escape_uri_component(matz_name)
    matz_name_sep = "\xE3\x81\xBE\xE3\x81\xA4 \xE3\x82\x82\xE3\x81\xA8" # Matsu moto
    assert_equal '%E3%81%BE%E3%81%A4%20%E3%82%82%E3%81%A8', EscapeUtils.escape_uri_component(matz_name_sep)
  end

  def test_uri_component_containing_pluses
    assert_equal "a%2Bplus", EscapeUtils.escape_uri_component("a+plus")
  end

  def test_uri_component_containing_slashes
    assert_equal "a%2Fslash", EscapeUtils.escape_uri_component("a/slash")
  end

  if RUBY_VERSION =~ /^1.9/
    def test_input_must_be_utf8_or_ascii
      str = "fo<o>bar"

      str.force_encoding 'ISO-8859-1'
      assert_raises Encoding::CompatibilityError do
        EscapeUtils.escape_uri_component(str)
      end

      str.force_encoding 'UTF-8'
      begin
        EscapeUtils.escape_uri_component(str)
      rescue Encoding::CompatibilityError => e
        assert_nil e, "#{e.class.name} raised, expected not to"
      end
    end

    def test_return_value_is_tagged_as_utf8
      str = "fo<o>bar"
      assert_equal Encoding.find('UTF-8'), EscapeUtils.escape_uri_component(str).encoding
    end
  end
end
