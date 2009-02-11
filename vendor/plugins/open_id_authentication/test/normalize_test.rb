require File.dirname(__FILE__) + '/test_helper'

class NormalizeTest < Test::Unit::TestCase
  include OpenIdAuthentication

  NORMALIZATIONS = {
    "openid.aol.com/nextangler"             => "http://openid.aol.com/nextangler",
    "http://openid.aol.com/nextangler"      => "http://openid.aol.com/nextangler",
    "https://openid.aol.com/nextangler"     => "https://openid.aol.com/nextangler",
    "HTTP://OPENID.AOL.COM/NEXTANGLER"      => "http://openid.aol.com/NEXTANGLER",
    "HTTPS://OPENID.AOL.COM/NEXTANGLER"     => "https://openid.aol.com/NEXTANGLER",
    "loudthinking.com"                      => "http://loudthinking.com/",
    "http://loudthinking.com"               => "http://loudthinking.com/",
    "http://loudthinking.com:80"            => "http://loudthinking.com/",
    "https://loudthinking.com:443"          => "https://loudthinking.com/",
    "http://loudthinking.com:8080"          => "http://loudthinking.com:8080/",
    "techno-weenie.net"                     => "http://techno-weenie.net/",
    "http://techno-weenie.net"              => "http://techno-weenie.net/",
    "http://techno-weenie.net  "            => "http://techno-weenie.net/",
    "=name"                                 => "=name"
  }

  def test_normalizations
    NORMALIZATIONS.each do |from, to|
      assert_equal to, normalize_identifier(from)
    end
  end

  def test_broken_open_id
    assert_raises(InvalidOpenId) { normalize_identifier(nil) }
  end
end
