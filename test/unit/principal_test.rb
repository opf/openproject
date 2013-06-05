#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../test_helper', __FILE__)

class PrincipalTest < ActiveSupport::TestCase

  context "#like" do
    setup do
      Principal.generate!(:login => 'login')
      Principal.generate!(:login => 'login2')

      Principal.generate!(:firstname => 'firstname')
      Principal.generate!(:firstname => 'firstname2')

      Principal.generate!(:lastname => 'lastname')
      Principal.generate!(:lastname => 'lastname2')

      Principal.generate!(:mail => 'mail@example.com')
      Principal.generate!(:mail => 'mail2@example.com')
    end

    should "search login" do
      results = Principal.like('login')

      assert_equal 2, results.count
      assert results.all? {|u| u.login.match(/login/) }
    end

    should "search firstname" do
      results = Principal.like('firstname')

      assert_equal 2, results.count
      assert results.all? {|u| u.firstname.match(/firstname/) }
    end

    should "search lastname" do
      results = Principal.like('lastname')

      assert_equal 2, results.count
      assert results.all? {|u| u.lastname.match(/lastname/) }
    end

    should "search mail" do
      results = Principal.like('mail')

      assert_equal 2, results.count
      assert results.all? {|u| u.mail.match(/mail/) }
    end
  end

end
