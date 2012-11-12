#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
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
  include MiniTest::Assertions

  def test_validations
    # factory valid
    assert FactoryGirl.build(:user_preference).valid?

    # user required
    refute FactoryGirl.build(:user_preference, :user => nil).valid?
  end

  def test_create
    user = FactoryGirl.create :user

    assert_kind_of UserPreference, user.pref
    assert_kind_of Hash, user.pref.others
    assert user.pref.save
  end

  def test_update
    user = FactoryGirl.create :user
    pref = FactoryGirl.create :user_preference, :user => user, :hide_mail => true
    assert_equal true, user.pref.hide_mail

    user.pref['preftest'] = 'value'
    assert user.pref.save

    user.reload
    assert_equal 'value', user.pref['preftest']
  end

  def test_update_with_method
    user = FactoryGirl.create :user
    assert_equal nil, user.pref.comments_sorting
    user.pref.comments_sorting = 'value'
    assert user.pref.save

    user.reload
    assert_equal 'value', user.pref.comments_sorting
  end
end
