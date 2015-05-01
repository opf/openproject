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

#-- encoding: UTF-8
require 'test_helper'

class UsersTest < Test::Unit::TestCase
  context 'The user responsible for an update' do
    setup do
      @updated_by = User.create(name: 'Steve Jobs')
      @user = User.create(name: 'Steve Richert')
    end

    should 'default to nil' do
      @user.update_attributes(first_name: 'Stephen')
      assert_nil @user.journals.last.user
    end

    should 'accept and return an ActiveRecord user' do
      @user.update_attributes(first_name: 'Stephen', updated_by: @updated_by)
      assert_equal @updated_by, @user.journals.last.user
    end

    should 'accept and return a string user name' do
      @user.update_attributes(first_name: 'Stephen', updated_by: @updated_by.name)
      assert_equal @updated_by.name, @user.journals.last.user
    end
  end
end
