#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require 'legacy_spec_helper'

describe UserPreference do
  include MiniTest::Assertions

  it 'should validations' do
    # factory valid
    assert FactoryGirl.build(:user_preference).valid?

    # user required
    refute FactoryGirl.build(:user_preference, user: nil).valid?
  end

  it 'should create' do
    user = FactoryGirl.create :user

    assert_kind_of UserPreference, user.pref
    assert_kind_of Hash, user.pref.others
    assert user.pref.save
  end

  it 'should update' do
    user = FactoryGirl.create :user
    pref = FactoryGirl.create :user_preference, user: user, hide_mail: true
    assert_equal true, user.pref.hide_mail

    user.pref['preftest'] = 'value'
    assert user.pref.save

    user.reload
    assert_equal 'value', user.pref['preftest']
  end

  it 'should update_with_method' do
    user = FactoryGirl.create :user
    assert_equal nil, user.pref.comments_sorting
    user.pref.comments_sorting = 'value'
    assert user.pref.save

    user.reload
    assert_equal 'value', user.pref.comments_sorting
  end
end
