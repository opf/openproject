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

RSpec.describe Principals::Scopes::HavingEntityMembership do
  shared_association_default(:status) { create(:status) }
  shared_association_default(:priority) { create(:priority) }
  shared_association_default(:author, factory_name: :user) { create(:user) }

  describe ".having_entity_membership" do
    subject { Principal.having_entity_membership(work_package) }

    context "with some sharing" do
      let(:project_role) { create(:project_role) }
      let(:view_work_package_role) { create(:view_work_package_role) }
      let(:comment_work_package_role) { create(:comment_work_package_role) }
      let(:edit_work_package_role) { create(:edit_work_package_role) }
      let(:project) do
        create(:project,
               members: { non_shared_project_user => [project_role],
                          shared_project_user => [project_role] })
      end
      let(:work_package) do
        create(:work_package, project:) do |wp|
          create(:work_package_member, entity: wp, user: view_user, roles: [view_work_package_role])
          create(:work_package_member, entity: wp, user: comment_user, roles: [comment_work_package_role])
          create(:work_package_member, entity: wp, user: edit_user, roles: [edit_work_package_role])
          create(:work_package_member, entity: wp, user: comment_group, roles: [comment_work_package_role])
          create(:work_package_member, entity: wp, user: shared_project_user, roles: [edit_work_package_role])
        end
      end

      let!(:view_user) { create(:user) }
      let!(:comment_user) { create(:user) }
      let!(:edit_user) { create(:user) }
      let!(:comment_group) { create(:group) }
      let!(:non_shared_project_user) { create(:user) }
      let!(:shared_project_user) { create(:user) }

      it "returns all those users having an entity membership" do
        expect(subject)
          .to contain_exactly(view_user,
                              comment_user,
                              edit_user,
                              comment_group,
                              shared_project_user)
      end
    end

    context "without any sharing" do
      let(:project) { create(:project) }
      let(:work_package) { create(:work_package, project:) }

      let!(:user) { create(:user) }

      it "is empty" do
        expect(subject).to be_empty
      end
    end
  end
end
