require File.expand_path('../helper', __FILE__)

class ContextTest < Test::Unit::TestCase
  def media_types; Proc.new {|c| c.media_types = %w< text/html > } end
  def charsets;    Proc.new {|c| c.charsets = %w< iso-8859-5 > }   end
  def encodings;   Proc.new {|c| c.encodings = %w< gzip > }        end
  def languages;   Proc.new {|c| c.languages = %w< en > }          end

  def test_empty
    request
    assert_equal(200, status)
  end

  def test_media_types
    request('HTTP_ACCEPT' => 'text/html')
    assert_equal(200, status)

    request('HTTP_ACCEPT' => 'text/html', &media_types)
    assert_equal(200, status)

    request('HTTP_ACCEPT' => 'text/plain', &media_types)
    assert_equal(406, status)
  end

  def test_charsets
    request('HTTP_ACCEPT_CHARSET' => 'iso-8859-5')
    assert_equal(200, status)

    request('HTTP_ACCEPT_CHARSET' => 'iso-8859-5', &charsets)
    assert_equal(200, status)

    request('HTTP_ACCEPT_CHARSET' => 'unicode-1-1', &charsets)
    assert_equal(406, status)
  end

  def test_encodings
    request('HTTP_ACCEPT_ENCODING' => 'gzip')
    assert_equal(200, status)

    request('HTTP_ACCEPT_ENCODING' => 'gzip', &encodings)
    assert_equal(200, status)

    request('HTTP_ACCEPT_ENCODING' => 'compress', &encodings)
    assert_equal(406, status)
  end

  def test_languages
    request('HTTP_ACCEPT_LANGUAGE' => 'en')
    assert_equal(200, status)

    request('HTTP_ACCEPT_LANGUAGE' => 'en', &languages)
    assert_equal(200, status)

    request('HTTP_ACCEPT_LANGUAGE' => 'jp', &languages)
    assert_equal(406, status)
  end
end
