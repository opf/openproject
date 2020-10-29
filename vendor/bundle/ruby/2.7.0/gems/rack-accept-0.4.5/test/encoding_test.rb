require File.expand_path('../helper', __FILE__)

class EncodingTest < Test::Unit::TestCase
  E = Rack::Accept::Encoding

  def test_qvalue
    e = E.new('')
    assert_equal(0, e.qvalue('gzip'))
    assert_equal(1, e.qvalue('identity'))

    e = E.new('gzip, *;q=0.5')
    assert_equal(1, e.qvalue('gzip'))
    assert_equal(0.5, e.qvalue('identity'))
  end

  def test_matches
    e = E.new('gzip, identity, *')
    assert_equal(%w{*}, e.matches(''))
    assert_equal(%w{gzip *}, e.matches('gzip'))
    assert_equal(%w{*}, e.matches('compress'))
  end

  def test_best_of
    e = E.new('gzip, compress')
    assert_equal('gzip', e.best_of(%w< gzip compress >))
    assert_equal('identity', e.best_of(%w< identity compress >))
    assert_equal(nil, e.best_of(%w< zip >))
  end
end
