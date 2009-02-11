require 'test/unit'
require 'openid/store/nonce'

module OpenID
  class NonceTestCase < Test::Unit::TestCase

     NONCE_RE = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ/

    def test_mk_nonce
      nonce = Nonce::mk_nonce
      assert(nonce.match(NONCE_RE))
      assert(nonce.size == 26)
    end

    def test_mk_nonce_time
      nonce = Nonce::mk_nonce(0)
      assert(nonce.match(NONCE_RE))
      assert(nonce.size == 26)
      assert(nonce.match(/^1970-01-01T00:00:00Z/))
    end

    def test_split
      s = '1970-01-01T00:00:00Z'
      expected_t = 0
      expected_salt = ''
      actual_t, actual_salt = Nonce::split_nonce(s)
      assert_equal(expected_t, actual_t)
      assert_equal(expected_salt, actual_salt)
    end

    def test_mk_split
      t = 42
      nonce_str = Nonce::mk_nonce(t)
      assert(nonce_str.match(NONCE_RE))
      at, salt = Nonce::split_nonce(nonce_str)
      assert_equal(6, salt.size)
      assert_equal(t, at)
    end

    def test_bad_split
      cases = [
        '',
        '1970-01-01T00:00:00+1:00',
        '1969-01-01T00:00:00Z',
        '1970-00-01T00:00:00Z',
        '1970.01-01T00:00:00Z',
        'Thu Sep  7 13:29:31 PDT 2006',
        'monkeys',
        ]
      cases.each{|c|
        assert_raises(ArgumentError, c.inspect) { Nonce::split_nonce(c) }
      }
    end

    def test_check_timestamp
      cases = [
        # exact, no allowed skew
        ['1970-01-01T00:00:00Z', 0, 0, true],

        # exact, large skew
        ['1970-01-01T00:00:00Z', 1000, 0, true],

        # no allowed skew, one second old
        ['1970-01-01T00:00:00Z', 0, 1, false],

        # many seconds old, outside of skew
        ['1970-01-01T00:00:00Z', 10, 50, false],

        # one second old, one second skew allowed
        ['1970-01-01T00:00:00Z', 1, 1, true],

        # One second in the future, one second skew allowed
        ['1970-01-01T00:00:02Z', 1, 1, true],

        # two seconds in the future, one second skew allowed
        ['1970-01-01T00:00:02Z', 1, 0, false],

        # malformed nonce string
        ['monkeys', 0, 0, false],
      ]
      
      cases.each{|c|
        (nonce_str, allowed_skew, now, expected) = c
        actual = Nonce::check_timestamp(nonce_str, allowed_skew, now)
        assert_equal(expected, actual, c.inspect)
      }
    end
  end
end
