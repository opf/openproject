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

class UserPreferenceTest < ActiveSupport::TestCase
  fixtures :users, :user_preferences

  def test_create
    user = User.new(:firstname => "new", :lastname => "user", :mail => "newuser@somenet.foo")
    user.login = "newuser"
    user.password, user.password_confirmation = "password", "password"
    assert user.save

    assert_kind_of UserPreference, user.pref
    assert_kind_of Hash, user.pref.others
    assert user.pref.save
  end

  def test_update
    user = User.find(1)
    assert_equal true, user.pref.hide_mail
    user.pref['preftest'] = 'value'
    assert user.pref.save

    user.reload
    assert_equal 'value', user.pref['preftest']
  end
end
