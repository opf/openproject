#-- copyright
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
#++

require "spec_helper"

RSpec.describe Principals::Scopes::Visible do
  describe ".visible" do
    shared_let(:role) { create(:project_role, permissions: %i[manage_members]) }

    shared_let(:anonymous_user) { User.anonymous }
    shared_let(:system_user) { User.system }

    shared_let(:project) { create(:project) }
    shared_let(:project_user) do
      create(:user, firstname: "project user",
                    member_with_roles: { project => role })
    end
    shared_let(:project_group) do
      create(:group, firstname: "project group",
                     member_with_roles: { project => role })
    end
    shared_let(:project_placeholder_user) do
      create(:placeholder_user, firstname: "project placeholder user",
                                member_with_roles: { project => role })
    end

    # The 'other project' is here to ensure their members are not visible from
    # the outside for people lacking manage_members or manage_user permissions
    shared_let(:other_project) { create(:project) }
    shared_let(:other_project_user) do
      create(:user, firstname: "other project user",
                    member_with_roles: { other_project => role })
    end
    shared_let(:other_project_group) do
      create(:group, firstname: "other project group",
                     member_with_roles: { other_project => role })
    end
    shared_let(:other_placeholder_user) do
      create(:placeholder_user, firstname: "other project placeholder user",
                                member_with_roles: { other_project => role })
    end

    shared_let(:global_user) { create(:user, firstname: "global user") }
    shared_let(:global_group) { create(:group, firstname: "global group") }
    shared_let(:global_placeholder_user) { create(:placeholder_user, firstname: "global placeholder") }

    subject { Principal.visible.to_a }

    shared_examples "sees all principals" do
      it "sees all users, groups, and placeholder users" do
        expect(subject).to contain_exactly(anonymous_user, system_user, current_user, project_user, other_project_user,
                                           global_user, project_group, other_project_group, global_group, project_placeholder_user, other_placeholder_user, global_placeholder_user)
      end
    end

    context "when user has manage_members project permission" do
      current_user do
        create(:user, firstname: "current user",
                      member_with_roles: { project => role })
      end

      include_examples "sees all principals"
    end

    context "when user has no manage_members project permission, and is member of a project" do
      current_user do
        create(:user, firstname: "current user",
                      member_with_permissions: { project => %i[view_work_packages] })
      end

      it "sees only the users, groups, and placeholder users in the same project" do
        expect(subject).to contain_exactly(current_user, project_user, project_group, project_placeholder_user)
      end
    end

    context "when user has manage_user global permission" do
      current_user { create(:user, firstname: "current user", global_permissions: %i[manage_user]) }

      include_examples "sees all principals"
    end

    context "when user has no permission" do
      current_user { create(:user, firstname: "current user") }

      it "sees only themself" do
        expect(subject).to contain_exactly(current_user)
      end
    end
  end
end
