#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require 'spec_helper'

describe Principal, type: :model do
  let(:user) { FactoryGirl.build(:user) }
  let(:group) { FactoryGirl.build(:group) }

  def self.should_return_groups_and_users_if_active(method, *params)
    it 'should return a user' do
      user.save!

      expect(Principal.send(method, *params)).to eq([user])
    end

    it 'should return a group' do
      group.save!

      expect(Principal.send(method, *params)).to eq([group])
    end

    it 'should not return the anonymous user' do
      User.anonymous

      expect(Principal.send(method, *params)).to eq([])
    end

    it 'should not return an inactive user' do
      user.status = User::STATUSES[:locked]

      user.save!

      expect(Principal.send(method, *params)).to eq([])
    end
  end

  describe 'active' do
    should_return_groups_and_users_if_active(:active_or_registered)

    it 'should not return a registerd user' do
      user.status = User::STATUSES[:registered]

      user.save!

      expect(Principal.active).to eq([])
    end
  end

  describe 'active_or_registered' do
    should_return_groups_and_users_if_active(:active_or_registered)

    it 'should return a registerd user' do
      user.status = User::STATUSES[:registered]

      user.save!

      expect(Principal.active_or_registered).to eq([user])
    end
  end

  describe 'active_or_registered_like' do
    def self.search
      'blubs'
    end

    let(:search) { self.class.search }

    before do
      user.lastname = search
      group.lastname = search
    end

    should_return_groups_and_users_if_active(:active_or_registered_like, search)

    it 'should return a registerd user' do
      user.status = User::STATUSES[:registered]

      user.save!

      expect(Principal.active_or_registered_like(search)).to eq([user])
    end

    it 'should not return a user if the name does not match' do
      user.save!

      expect(Principal.active_or_registered_like(user.lastname + '123')).to eq([])
    end

    it 'should return a group if the name does match partially' do
      user.save!

      expect(Principal.active_or_registered_like(user.lastname[0, -1])).to eq([user])
    end
  end
end
