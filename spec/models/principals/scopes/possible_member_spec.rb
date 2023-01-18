#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

describe Principals::Scopes::PossibleMember do
  let(:project) { create(:project) }
  let(:public_project) { create(:project, public: true) }
  let(:role) { create(:role) }
  # Non-member role is needed to see public projects
  let!(:non_member_role) { create(:non_member) }
  let!(:active_user) { create(:user) }
  let!(:admin_user) { create(:admin) }
  let!(:global_manager) { create(:user, global_permission: :manage_user) }
  let!(:locked_user) { create(:user, status: :locked) }
  let!(:registered_user) { create(:user, status: :registered) }
  let!(:invited_user) { create(:user, status: :invited) }
  let!(:anonymous_user) { create(:anonymous) }
  let!(:placeholder_user) { create(:placeholder_user) }
  let!(:group) { create(:group) }
  let!(:member_user) do
    create(:user,
           member_in_project: project,
           member_through_role: role)
  end
  let!(:member_in_public_project) do
    create(:user,
           member_in_project: public_project,
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

  describe '.possible_member' do
    subject { Principal.possible_member(project) }

    context 'as a simple user' do
      current_user { active_user }

      it 'returns non locked users, groups and placeholder users not part of the project yet' do
        expect(subject).to match_array([
                                         active_user,
                                         member_in_public_project
                                       ])
      end
    end

    context 'as a user with global permission to manage users' do
      current_user { global_manager }

      it 'returns non locked users, groups and placeholder users not part of the project yet' do
        expect(subject).to match_array([
                                         admin_user,
                                         global_manager,
                                         active_user,
                                         registered_user,
                                         invited_user,
                                         placeholder_user,
                                         group,
                                         member_in_public_project
                                       ])
      end
    end

    context 'as an admin' do
      current_user { admin_user }

      it 'returns non locked users, groups and placeholder users not part of the project yet' do
        expect(subject).to match_array([
                                         admin_user,
                                         global_manager,
                                         active_user,
                                         registered_user,
                                         invited_user,
                                         placeholder_user,
                                         group,
                                         member_in_public_project
                                       ])
      end
    end
  end
end
