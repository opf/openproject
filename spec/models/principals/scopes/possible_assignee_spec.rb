#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Principals::Scopes::PossibleAssignee, type: :model do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role_assignable) { true }
  let(:role) { create(:role, assignable: role_assignable) }
  let(:user_status) { :active }
  let!(:member_user) do
    create(:user,
                      status: user_status,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:member_placeholder_user) do
    create(:placeholder_user,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:member_group) do
    create(:group,
                      member_in_project: project,
                      member_through_role: role)
  end
  let!(:other_project_member_user) do
    create(:group,
                      member_in_project: other_project,
                      member_through_role: role)
  end

  describe '.possible_assignee' do
    subject { Principal.possible_assignee(project) }

    context 'with the role being assignable' do
      context 'with the user status being active' do
        it 'returns non locked users, groups and placeholder users that are members' do
          is_expected
            .to match_array([member_user,
                             member_placeholder_user,
                             member_group])
        end
      end

      context 'with the user status being registered' do
        let(:user_status) { :registered }

        it 'returns non locked users, groups and placeholder users that are members' do
          is_expected
            .to match_array([member_user,
                             member_placeholder_user,
                             member_group])
        end
      end

      context 'with the user status being invited' do
        let(:user_status) { :invited }

        it 'returns non locked users, groups and placeholder users that are members' do
          is_expected
            .to match_array([member_user,
                             member_placeholder_user,
                             member_group])
        end
      end

      context 'with the user status being locked' do
        let(:user_status) { :locked }

        it 'returns non locked users, groups and placeholder users that are members' do
          is_expected
            .to match_array([member_placeholder_user,
                             member_group])
        end
      end
    end

    context 'with the role not being assignable' do
      let(:role_assignable) { false }

      it 'returns nothing' do
        is_expected
          .to be_empty
      end
    end
  end
end
