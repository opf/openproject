require File.expand_path('../helper', __FILE__)

class RequestTest < Test::Unit::TestCase
  R = Rack::Accept::Request

  def test_media_type
    r = R.new('HTTP_ACCEPT' => 'text/*;q=0, text/html')
    assert(r.media_type?('text/html'))
    assert(r.media_type?('text/html;level=1'))
    assert(!r.media_type?('text/plain'))
    assert(!r.media_type?('image/png'))

    request = R.new('HTTP_ACCEPT' => '*/*')
    assert(request.media_type?('image/png'))
  end

  def test_charset
    r = R.new('HTTP_ACCEPT_CHARSET' => 'iso-8859-5, unicode-1-1;q=0.8')
    assert(r.charset?('iso-8859-5'))
    assert(r.charset?('unicode-1-1'))
    assert(r.charset?('iso-8859-1'))
    assert(!r.charset?('utf-8'))

    r = R.new('HTTP_ACCEPT_CHARSET' => 'iso-8859-1;q=0')
    assert(!r.charset?('iso-8859-1'))
  end

  def test_encoding
    r = R.new('HTTP_ACCEPT_ENCODING' => '')
    assert(r.encoding?('identity'))
    assert(!r.encoding?('gzip'))

    r = R.new('HTTP_ACCEPT_ENCODING' => 'gzip')
    assert(r.encoding?('identity'))
    assert(r.encoding?('gzip'))
    assert(!r.encoding?('compress'))

    r = R.new('HTTP_ACCEPT_ENCODING' => 'gzip;q=0, *')
    assert(r.encoding?('compress'))
    assert(r.encoding?('identity'))
    assert(!r.encoding?('gzip'))

    r = R.new('HTTP_ACCEPT_ENCODING' => 'identity;q=0')
    assert(!r.encoding?('identity'))

    r = R.new('HTTP_ACCEPT_ENCODING' => '*;q=0')
    assert(!r.encoding?('identity'))
  end

  def test_language
    request = R.new({})
    assert(request.language?('en'))
    assert(request.language?('da'))

    request = R.new('HTTP_ACCEPT_LANGUAGE' => 'en;q=0.5, en-gb')
    assert(request.language?('en'))
    assert(request.language?('en-gb'))
    assert(!request.language?('da'))
  end
end
