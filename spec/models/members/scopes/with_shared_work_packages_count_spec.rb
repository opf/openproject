# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe Members::Scopes::WithSharedWorkPackagesCount do
  let(:project) { create(:project) }
  let(:other_project) { create(:project) }
  let(:role) { create(:project_role) }

  let(:work_package) { create(:work_package, project:) }
  let(:work_package2) { create(:work_package, project:) }

  let(:view_work_package_role) { create(:view_work_package_role) }
  let(:comment_work_package_role) { create(:comment_work_package_role) }

  let(:shared_user) { create(:user, status: Principal.statuses[:active]) }
  let(:other_shared_user) { create(:user, status: Principal.statuses[:active]) }

  let(:group) { create(:group, members: [other_shared_user]) }

  let!(:active_user_member) do
    create(:member,
           project:,
           roles: [role],
           principal: create(:user, status: Principal.statuses[:active]))
  end
  let!(:active_user_shared_member_view) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package,
           principal: shared_user)
  end
  let!(:active_user_shared_member_comment) do
    create(:member,
           project:,
           roles: [comment_work_package_role],
           entity: work_package2,
           principal: shared_user)
  end
  let!(:other_shared_member) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package,
           principal: other_shared_user)
  end

  let!(:group_shared_member) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package,
           principal: group)
  end

  before do
    Groups::CreateInheritedRolesService
      .new(group, current_user: create(:admin))
      .call(user_ids: group.user_ids,
            send_notifications: false,
            project_ids: [project.id])
  end

  describe '.with_shared_work_packages_count' do
    subject do
      Member
        .with_shared_work_packages_count(only_role_id:)
        .map{ |m| [m.id, m.shared_work_packages_count] }
    end

    context 'when only_role_ids is not set' do
      let(:only_role_id) { nil }

      it 'returns the total count of shared roles' do
        expect(subject).to contain_exactly [active_user_member.id, 0],
                                           [active_user_shared_member_view.id, 2],
                                           [active_user_shared_member_comment.id, 2],
                                           [other_shared_member.id, 1],
                                           [group_shared_member.id, 1]
      end
    end

    context 'when only_role_id is set to view' do
      let(:only_role_id) { view_work_package_role.id }

      it 'returns the total count of view roles' do
        expect(subject).to contain_exactly [active_user_member.id, 0],
                                           [active_user_shared_member_view.id, 1],
                                           # this is 1 due to it counting for the principal
                                           [active_user_shared_member_comment.id, 1],
                                           [other_shared_member.id, 1],
                                           [group_shared_member.id, 1]
      end
    end

    context 'when only_role_id is set to comment' do
      let(:only_role_id) { comment_work_package_role.id }

      it 'returns the total count of the comment roles' do
        expect(subject).to contain_exactly [active_user_member.id, 0],
                                           # this is 1 due to it counting for the principal
                                           [active_user_shared_member_view.id, 1],
                                           [active_user_shared_member_comment.id, 1],
                                           [other_shared_member.id, 0],
                                           [group_shared_member.id, 0]
      end
    end
  end
end
