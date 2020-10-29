require File.expand_path("../helper", __FILE__)

class Object
  def html_safe?
    false
  end
end

class TestSafeBuffer < String
  def html_safe?
    true
  end

  def html_safe
    self
  end

  def to_s
    self
  end
end

class String
  def html_safe
    TestSafeBuffer.new(self)
  end
end

class HtmlEscapeTest < Minitest::Test
  include EscapeUtils::HtmlSafety

  def test_marks_escaped_strings_safe
    escaped = _escape_html("<strong>unsafe</strong>")
    assert_equal "&lt;strong&gt;unsafe&lt;&#47;strong&gt;", escaped
    assert escaped.html_safe?
  end

  def test_doesnt_escape_safe_strings
    assert_equal "<p>safe string</p>", _escape_html("<p>safe string</p>".html_safe)
  end

  def test_
    assert_equal "5", _escape_html(5)
    assert_equal "hello", _escape_html(:hello)
  end
end
