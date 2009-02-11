require 'test/unit'
require 'openid/dh'
require 'testutil'

module OpenID
  class DiffieHellmanExposed < OpenID::DiffieHellman
    def DiffieHellmanExposed.strxor_for_testing(a, b)
      return DiffieHellmanExposed.strxor(a, b)
    end
  end

  class DiffieHellmanTestCase < Test::Unit::TestCase
    include OpenID::TestDataMixin

    NUL = "\x00"

    def test_strxor_success
      [#input 1   input 2   expected
       [NUL,      NUL,      NUL     ],
       ["\x01",   NUL,      "\x01"  ],
       ["a",      "a",      NUL     ],
       ["a",      NUL,      "a"     ],
       ["abc",    NUL * 3,  "abc"   ],
       ["x" * 10, NUL * 10, "x" * 10],
       ["\x01",   "\x02",   "\x03"  ],
       ["\xf0",   "\x0f",   "\xff"  ],
       ["\xff",   "\x0f",   "\xf0"  ],
      ].each do |input1, input2, expected|
        actual = DiffieHellmanExposed.strxor_for_testing(input1, input2)
        assert_equal(expected, actual)
      end
    end

    def test_strxor_failure
      [
       ['',      'a'    ],
       ['foo',   'ba'   ],
       [NUL * 3, NUL * 4],
       [255,     127    ].map{|h| (0..h).map{|i|i.chr}.join('')},
      ].each do |aa, bb|
        assert_raises(ArgumentError) {
          DiffieHellmanExposed.strxor(aa, bb)
        }
      end
    end

    def test_simple_exchange
      dh1 = DiffieHellman.from_defaults()
      dh2 = DiffieHellman.from_defaults()
      secret1 = dh1.get_shared_secret(dh2.public)
      secret2 = dh2.get_shared_secret(dh1.public)
      assert_equal(secret1, secret2)
    end

    def test_xor_secret
      dh1 = DiffieHellman.from_defaults()
      dh2 = DiffieHellman.from_defaults()
      secret = "Shhhhhh! don't tell!"
      encrypted = dh1.xor_secret((CryptUtil.method :sha1), dh2.public, secret)
      decrypted = dh2.xor_secret((CryptUtil.method :sha1), dh1.public, encrypted)
      assert_equal(secret, decrypted)
    end

    def test_dh
      dh = DiffieHellman.from_defaults()
      class << dh
        def set_private_test(priv)
          set_private(priv)
        end
      end

      read_data_file('dh.txt', true).each do |line|
        priv, pub = line.split(' ').map {|x| x.to_i}
        dh.set_private_test(priv)
        assert_equal(dh.public, pub)
      end
    end

    def test_using_defaults
      dh = DiffieHellman.from_defaults()
      assert(dh.using_default_values?)
      dh = DiffieHellman.new(3, 2750161)
      assert(!dh.using_default_values?)
    end
  end
end
