# $Id: testber.rb 57 2006-04-18 00:18:48Z blackhedd $
#
#


$:.unshift "lib"

require 'net/ldap'
require 'stringio'


class TestBer < Test::Unit::TestCase

  def setup
  end

  # TODO: Add some much bigger numbers
  # 5000000000 is a Bignum, which hits different code.
  def test_ber_integers
    assert_equal( "\002\001\005", 5.to_ber )
    assert_equal( "\002\002\203t", 500.to_ber )
    assert_equal( "\002\003\203\206P", 50000.to_ber )
    assert_equal( "\002\005\222\320\227\344\000", 5000000000.to_ber )
  end

  def test_ber_parsing
    assert_equal( 6, "\002\001\006".read_ber( Net::LDAP::AsnSyntax ))
    assert_equal( "testing", "\004\007testing".read_ber( Net::LDAP::AsnSyntax ))
  end


  def test_ber_parser_on_ldap_bind_request
    s = StringIO.new "0$\002\001\001`\037\002\001\003\004\rAdministrator\200\vad_is_bogus"
    assert_equal( [1, [3, "Administrator", "ad_is_bogus"]], s.read_ber( Net::LDAP::AsnSyntax ))
  end




end


