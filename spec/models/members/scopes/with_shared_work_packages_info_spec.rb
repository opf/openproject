# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require "spec_helper"

RSpec.describe Members::Scopes::WithSharedWorkPackagesInfo do
  let(:project) { create(:project) }
  let(:role) { create(:project_role) }

  let(:work_package_a) { create(:work_package, project:) }
  let(:work_package_b) { create(:work_package, project:) }

  let(:only_wp_a) { [work_package_a.id] }
  let(:only_wp_b) { [work_package_b.id] }
  let(:both_wps) { contain_exactly(work_package_a.id, work_package_b.id) }

  let(:view_work_package_role) { create(:view_work_package_role) }
  let(:comment_work_package_role) { create(:comment_work_package_role) }

  let(:user_a) { create(:user, lastname: "a", status: Principal.statuses[:active]) }
  let(:user_b) { create(:user, lastname: "b", status: Principal.statuses[:active]) }
  let(:user_c) { create(:user, lastname: "c", status: Principal.statuses[:active]) }
  let(:group) { create(:group, lastname: "g", members: [user_b, user_c]) }

  let!(:active_user_member) do
    create(:member,
           project:,
           roles: [role],
           principal: create(:user, lastname: "x", status: Principal.statuses[:active]))
  end
  let!(:user_a_view_member) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package_a,
           principal: user_a)
  end
  let!(:user_a_comment_member) do
    create(:member,
           project:,
           roles: [comment_work_package_role],
           entity: work_package_b,
           principal: user_a)
  end
  let!(:user_b_view_member) do
    create(:member,
           project:,
           roles: [view_work_package_role],
           entity: work_package_a,
           principal: user_b)
  end
  let(:user_c_inherited_member) do
    Member.find_by(entity: work_package_a, principal: user_c)
  end

  let!(:group_comment_member) do
    create(:member,
           project:,
           roles: [comment_work_package_role],
           entity: work_package_a,
           principal: group)
  end

  before do
    Groups::CreateInheritedRolesService
      .new(group, current_user: create(:admin))
      .call(user_ids: group.user_ids,
            send_notifications: false,
            project_ids: [project.id])
  end

  describe ".with_shared_work_packages_info" do
    subject do
      Member
        .with_shared_work_packages_info(only_role_id:)
        .map do |m|
          [
            m.principal.lastname,
            m.id,
            {
              ids: m.shared_work_package_ids,
              other: m.other_shared_work_packages_count,
              direct: m.direct_shared_work_packages_count,
              inherited: m.inherited_shared_work_packages_count,
              total: m.all_shared_work_packages_count
            }
          ]
        end
    end

    context "when only_role_ids is not set" do
      let(:only_role_id) { nil }

      it "returns info for all roles" do
        expect(subject).to contain_exactly(
          ["x", active_user_member.id,      { ids: [],        other: 0, direct: 0, inherited: 0, total: 0 }],
          ["a", user_a_view_member.id,      { ids: both_wps,  other: 0, direct: 2, inherited: 0, total: 2 }],
          ["a", user_a_comment_member.id,   { ids: both_wps,  other: 0, direct: 2, inherited: 0, total: 2 }],
          ["b", user_b_view_member.id,      { ids: only_wp_a, other: 0, direct: 1, inherited: 1, total: 1 }],
          ["g", group_comment_member.id,    { ids: only_wp_a, other: 0, direct: 1, inherited: 0, total: 1 }],
          ["c", user_c_inherited_member.id, { ids: only_wp_a, other: 0, direct: 0, inherited: 1, total: 1 }]
        )
      end
    end

    context "when only_role_id is set to view" do
      let(:only_role_id) { view_work_package_role.id }

      it "returns info for view roles" do
        expect(subject).to contain_exactly(
          ["x", active_user_member.id,      { ids: [],        other: 0, direct: 0, inherited: 0, total: 0 }],
          ["a", user_a_view_member.id,      { ids: only_wp_a, other: 1, direct: 1, inherited: 0, total: 2 }],
          ["a", user_a_comment_member.id,   { ids: only_wp_a, other: 1, direct: 1, inherited: 0, total: 2 }],
          ["b", user_b_view_member.id,      { ids: only_wp_a, other: 1, direct: 1, inherited: 0, total: 1 }],
          ["g", group_comment_member.id,    { ids: [],        other: 1, direct: 0, inherited: 0, total: 1 }],
          ["c", user_c_inherited_member.id, { ids: [],        other: 1, direct: 0, inherited: 0, total: 1 }]
        )
      end
    end

    context "when only_role_id is set to comment" do
      let(:only_role_id) { comment_work_package_role.id }

      it "returns info for comment roles" do
        expect(subject).to contain_exactly(
          ["x", active_user_member.id,      { ids: [],        other: 0, direct: 0, inherited: 0, total: 0 }],
          ["a", user_a_view_member.id,      { ids: only_wp_b, other: 1, direct: 1, inherited: 0, total: 2 }],
          ["a", user_a_comment_member.id,   { ids: only_wp_b, other: 1, direct: 1, inherited: 0, total: 2 }],
          ["b", user_b_view_member.id,      { ids: only_wp_a, other: 1, direct: 0, inherited: 1, total: 1 }],
          ["g", group_comment_member.id,    { ids: only_wp_a, other: 0, direct: 1, inherited: 0, total: 1 }],
          ["c", user_c_inherited_member.id, { ids: only_wp_a, other: 0, direct: 0, inherited: 1, total: 1 }]
        )
      end
    end
  end
end
