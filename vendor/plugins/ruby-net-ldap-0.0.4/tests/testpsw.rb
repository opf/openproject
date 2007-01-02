# $Id: testpsw.rb 72 2006-04-24 21:58:14Z blackhedd $
#
#


$:.unshift "lib"

require 'net/ldap'
require 'stringio'


class TestPassword < Test::Unit::TestCase

  def setup
  end


  def test_psw
    assert_equal( "{MD5}xq8jwrcfibi0sZdZYNkSng==", Net::LDAP::Password.generate( :md5, "cashflow" ))
    assert_equal( "{SHA}YE4eGkN4BvwNN1f5R7CZz0kFn14=", Net::LDAP::Password.generate( :sha, "cashflow" ))
  end




end


