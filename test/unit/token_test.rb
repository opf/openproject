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

class TokenTest < ActiveSupport::TestCase
  fixtures :all

  def test_create
    token = Token.new
    token.save
    assert_equal 40, token.value.length
    assert !token.expired?
  end

  def test_create_should_remove_existing_tokens
    user = User.find(1)
    t1 = Token.create(:user => user, :action => 'autologin')
    t2 = Token.create(:user => user, :action => 'autologin')
    assert_not_equal t1.value, t2.value
    assert !Token.exists?(t1.id)
    assert  Token.exists?(t2.id)
  end
end
