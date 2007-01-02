# $Id: testldap.rb 65 2006-04-23 01:17:49Z blackhedd $
#
#


$:.unshift "lib"

require 'test/unit'

require 'net/ldap'
require 'stringio'


class TestLdapClient < Test::Unit::TestCase

  # TODO: these tests crash and burn if the associated
  # LDAP testserver isn't up and running.
  # We rely on being able to read a file with test data
  # in LDIF format.
  # TODO, WARNING: for the moment, this data is in a file
  # whose name and location are HARDCODED into the
  # instance method load_test_data.

  def setup
    @host = "127.0.0.1"
    @port = 3890
    @auth = {
      :method => :simple,
      :username => "cn=bigshot,dc=bayshorenetworks,dc=com",
      :password => "opensesame"
    }

    @ldif = load_test_data
  end



  # Get some test data which will be used to validate
  # the responses from the test LDAP server we will
  # connect to.
  # TODO, Bogus: we are HARDCODING the location of the file for now.
  #
  def load_test_data
    ary = File.readlines( "tests/testdata.ldif" )
    hash = {}
    while line = ary.shift and line.chomp!
      if line =~ /^dn:[\s]*/i
        dn = $'
        hash[dn] = {}
        while attr = ary.shift and attr.chomp! and attr =~ /^([\w]+)[\s]*:[\s]*/
          hash[dn][$1.downcase.intern] ||= []
          hash[dn][$1.downcase.intern] << $'
        end
      end
    end
    hash
  end



  # Binding tests.
  # Need tests for all kinds of network failures and incorrect auth.
  # TODO: Implement a class-level timeout for operations like bind.
  # Search has a timeout defined at the protocol level, other ops do not.
  # TODO, use constants for the LDAP result codes, rather than hardcoding them.
  def test_bind
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => @auth
    assert_equal( true, ldap.bind )
    assert_equal( 0, ldap.get_operation_result.code )
    assert_equal( "Success", ldap.get_operation_result.message )

    bad_username = @auth.merge( {:username => "cn=badguy,dc=imposters,dc=com"} )
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => bad_username
    assert_equal( false, ldap.bind )
    assert_equal( 48, ldap.get_operation_result.code )
    assert_equal( "Inappropriate Authentication", ldap.get_operation_result.message )

    bad_password = @auth.merge( {:password => "cornhusk"} )
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => bad_password
    assert_equal( false, ldap.bind )
    assert_equal( 49, ldap.get_operation_result.code )
    assert_equal( "Invalid Credentials", ldap.get_operation_result.message )
  end



  def test_search
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => @auth

    search = {:base => "dc=smalldomain,dc=com"}
    assert_equal( false, ldap.search( search ))
    assert_equal( 32, ldap.get_operation_result.code )
    
    search = {:base => "dc=bayshorenetworks,dc=com"}
    assert_equal( true, ldap.search( search ))
    assert_equal( 0, ldap.get_operation_result.code )
    
    ldap.search( search ) {|res|
      assert_equal( res, @ldif )
    }
  end
    



  # This is a helper routine for test_search_attributes.
  def internal_test_search_attributes attrs_to_search
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => @auth
    assert( ldap.bind )

    search = {
      :base => "dc=bayshorenetworks,dc=com",
      :attributes => attrs_to_search
    }

    ldif = @ldif
    ldif.each {|dn,entry|
      entry.delete_if {|attr,value|
        ! attrs_to_search.include?(attr)
      }
    }
  
    assert_equal( true, ldap.search( search ))
    ldap.search( search ) {|res|
      res_keys = res.keys.sort
      ldif_keys = ldif.keys.sort
      assert( res_keys, ldif_keys )
      res.keys.each {|rk|
        assert( res[rk], ldif[rk] )
      }
    }
  end


  def test_search_attributes
    internal_test_search_attributes [:mail]
    internal_test_search_attributes [:cn]
    internal_test_search_attributes [:ou]
    internal_test_search_attributes [:hasaccessprivilege]
    internal_test_search_attributes ["mail"]
    internal_test_search_attributes ["cn"]
    internal_test_search_attributes ["ou"]
    internal_test_search_attributes ["hasaccessrole"]

    internal_test_search_attributes [:mail, :cn, :ou, :hasaccessrole]
    internal_test_search_attributes [:mail, "cn", :ou, "hasaccessrole"]
  end


  def test_search_filters
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => @auth
    search = {
      :base => "dc=bayshorenetworks,dc=com",
      :filter => Net::LDAP::Filter.eq( "sn", "Fosse" )
    }

    ldap.search( search ) {|res|
      p res
    }
  end



  def test_open
    ldap = Net::LDAP.new :host => @host, :port => @port, :auth => @auth
    ldap.open {|ldap|
      10.times {
        rc = ldap.search( :base => "dc=bayshorenetworks,dc=com" )
        assert_equal( true, rc )
      }
    }
  end


  def test_ldap_open
    Net::LDAP.open( :host => @host, :port => @port, :auth => @auth ) {|ldap|
      10.times {
        rc = ldap.search( :base => "dc=bayshorenetworks,dc=com" )
        assert_equal( true, rc )
      }
    }
  end





end


