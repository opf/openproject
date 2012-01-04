#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class AuthSourceLdapTest < ActiveSupport::TestCase
  fixtures :auth_sources

  def setup
  end

  def test_create
    a = AuthSourceLdap.new(:name => 'My LDAP', :host => 'ldap.example.net', :port => 389, :base_dn => 'dc=example,dc=net', :attr_login => 'sAMAccountName')
    assert a.save
  end

  def test_should_strip_ldap_attributes
    a = AuthSourceLdap.new(:name => 'My LDAP', :host => 'ldap.example.net', :port => 389, :base_dn => 'dc=example,dc=net', :attr_login => 'sAMAccountName',
                           :attr_firstname => 'givenName ')
    assert a.save
    assert_equal 'givenName', a.reload.attr_firstname
  end

  context "validations" do
    should "validate that custom_filter is a valid LDAP filter" do
      @auth = AuthSourceLdap.new(:name => 'Validation', :host => 'localhost', :port => 389, :attr_login => 'login')
      @auth.custom_filter = "(& (homeDirectory=*) (sn=O*" # Missing ((
      assert @auth.invalid?
      assert_equal "is invalid", @auth.errors.on(:custom_filter)

      @auth.custom_filter = "(& (homeDirectory=*) (sn=O*))"
      assert @auth.valid?
      assert_equal nil, @auth.errors.on(:custom_filter)

    end
  end

  if ldap_configured?
    context '#authenticate' do
      setup do
        @auth = AuthSourceLdap.find(1)
      end

      context 'with a valid LDAP user' do
        should 'return the user attributes' do
          attributes =  @auth.authenticate('example1','123456')
          assert attributes.is_a?(Hash), "An hash was not returned"
          assert_equal 'Example', attributes[:firstname]
          assert_equal 'One', attributes[:lastname]
          assert_equal 'example1@redmine.org', attributes[:mail]
          assert_equal @auth.id, attributes[:auth_source_id]
          attributes.keys.each do |attribute|
            assert User.new.respond_to?("#{attribute}="), "Unexpected :#{attribute} attribute returned"
          end
        end
      end

      context 'with an invalid LDAP user' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('nouser','123456')
        end
      end

      context 'without a login' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('','123456')
        end
      end

      context 'without a password' do
        should 'return nil' do
          assert_equal nil, @auth.authenticate('edavis','')
        end
      end

      context "using a valid custom filter" do
        setup do
          @auth.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*))")
        end

        should "find a user who authenticates and matches the custom filter" do
          assert_not_nil @auth.authenticate('example1', '123456')
        end

        should "be nil for users who don't match the custom filter" do
          assert_nil @auth.authenticate('edavis', '123456')
        end
      end

      context "using an invalid custom filter" do
        setup do
          # missing )) at the end
          @auth.update_attributes(:custom_filter => "(& (homeDirectory=*) (sn=O*")
        end

        should "skip the custom filter" do
          assert_not_nil @auth.authenticate('example1', '123456')
          assert_not_nil @auth.authenticate('edavis', '123456')
        end
      end

    end
  else
    puts '(Test LDAP server not configured)'
  end
end
