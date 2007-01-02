# $Id: testfilter.rb 122 2006-05-15 20:03:56Z blackhedd $
#
#

require 'test/unit'

$:.unshift "lib"

require 'net/ldap'


class TestFilter < Test::Unit::TestCase

  def setup
  end


  def teardown
  end

  def test_rfc_2254
    p Net::LDAP::Filter.from_rfc2254( " ( uid=george*   ) " )
    p Net::LDAP::Filter.from_rfc2254( "uid!=george*" )
    p Net::LDAP::Filter.from_rfc2254( "uid<george*" )
    p Net::LDAP::Filter.from_rfc2254( "uid <= george*" )
    p Net::LDAP::Filter.from_rfc2254( "uid>george*" )
    p Net::LDAP::Filter.from_rfc2254( "uid>=george*" )
    p Net::LDAP::Filter.from_rfc2254( "uid!=george*" )

    p Net::LDAP::Filter.from_rfc2254( "(& (uid!=george* ) (mail=*))" )
    p Net::LDAP::Filter.from_rfc2254( "(| (uid!=george* ) (mail=*))" )
    p Net::LDAP::Filter.from_rfc2254( "(! (mail=*))" )
  end


end

