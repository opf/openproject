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

require 'spec_helper'

describe User::Authorization, type: :model do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role) }
  let(:user1) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:user2) do
    FactoryGirl.create(:user,
                       member_in_project: project,
                       member_through_role: role)
  end
  let(:other_project) { FactoryGirl.create(:project) }
  let(:other_user) do
    FactoryGirl.create(:user,
                       member_in_project: other_project,
                       member_through_role: role)
  end
  let(:users) do
    [user1, user2]
  end

  describe '.authorize_within' do
    before do
      users
      other_user
    end

    it 'takes a block that gets all the users that are members of the project' do
      User.authorize_within(project) do |scope|
        expect(scope.all).to match_array users

        scope.all
      end
    end

    it 'returns the users that are returned by the block' do
      returned_users = User.authorize_within(project) do |_|
        [users.first]
      end

      expect(returned_users).to match_array [users.first]
    end

    it 'returns users without the associations being preloaded' do
      returned_users = User.authorize_within(project) { |scope| scope.all }

      expect((returned_users.map { |u| u.association_cache.keys }).flatten).to be_empty
    end

    it 'throws an error unless an array of users is returned' do
      expect { User.authorize_within(project) { [nil] } }.to raise_error(ArgumentError)
    end
  end
end
