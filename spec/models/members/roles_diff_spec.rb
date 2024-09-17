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

RSpec.describe Members::RolesDiff do
  let(:project) { build_stubbed(:project) }
  let(:group) { build_stubbed(:group) }
  let(:user) { build_stubbed(:user) }
  let(:role) { build_stubbed(:project_role) }
  let(:role_other) { build_stubbed(:project_role) }

  let(:group_member_role) { build_stubbed(:member_role, role:) }
  let(:group_member_role_other) { build_stubbed(:member_role, role: role_other) }
  let(:group_member_roles) { raise NotImplementedError("please set group_member_roles") }
  let(:group_member) do
    build_stubbed(:member, principal: group, project:, member_roles: group_member_roles)
  end

  let(:user_member_role) do
    build_stubbed(:member_role, role:)
  end
  let(:user_member_role_inherited) do
    build_stubbed(:member_role, role:, inherited_from: group_member_role.id)
  end
  let(:user_member_role_other) do
    build_stubbed(:member_role, role: role_other)
  end
  let(:user_member_role_other_inherited) do
    build_stubbed(:member_role, role: role_other, inherited_from: group_member_role_other.id)
  end
  let(:user_member_roles) { raise NotImplementedError("please set user_member_roles") }
  let(:user_member) do
    build_stubbed(:member, principal: user, project:, member_roles: user_member_roles)
  end

  subject(:difference) do
    described_class.new(user_member, group_member)
  end

  shared_examples "roles created" do
    it "results in roles created" do
      expect(difference.result).to eq(:roles_created)
    end
  end

  shared_examples "roles updated" do
    it "results in roles updated" do
      expect(difference.result).to eq(:roles_updated)
    end
  end

  shared_examples "roles unchanged" do
    it "results in roles unchanged" do
      expect(difference.result).to eq(:roles_unchanged)
    end
  end

  context "when group has added all its roles to a user" do
    let(:group_member_roles) { [group_member_role, group_member_role_other] }
    let(:user_member_roles) do
      [
        user_member_role_inherited,
        user_member_role_other_inherited
      ]
    end

    include_examples "roles created"
  end

  context "when group has added all its roles to a user who already had some preexisting other roles" do
    let(:group_member_roles) { [group_member_role] }
    let(:user_member_roles) do
      [
        user_member_role_other,
        user_member_role_inherited
      ]
    end

    include_examples "roles updated"
  end

  context "when group has added a new role and an existing role to a user" do
    let(:group_member_roles) { [group_member_role, group_member_role_other] }
    let(:user_member_roles) do
      [
        user_member_role,
        user_member_role_inherited,
        user_member_role_other_inherited
      ]
    end

    include_examples "roles updated"
  end

  context "when group has added already existing roles to a user" do
    let(:group_member_roles) { [group_member_role, group_member_role_other] }
    let(:user_member_roles) do
      [
        user_member_role,
        user_member_role_other,
        user_member_role_inherited,
        user_member_role_other_inherited
      ]
    end

    include_examples "roles unchanged"
  end

  context "when group did not add any roles" do
    let(:group_member_roles) { [group_member_role, group_member_role_other] }
    let(:user_member_roles) do
      [
        user_member_role,
        user_member_role_other
      ]
    end

    include_examples "roles unchanged"
  end

  context "when the projects are different between members" do
    let(:group_member) do
      build_stubbed(
        :member,
        principal: group,
        project: create(:project)
      )
    end
    let(:user_member) do
      build_stubbed(
        :member,
        principal: user,
        project: create(:project)
      )
    end

    it "raises ArgumentError" do
      expect { difference.result }.to raise_error(ArgumentError)
    end
  end

  context "with another group defined" do
    let(:other_group_member_role) { build_stubbed(:member_role, role:) }
    let(:other_group_member_role_other) { build_stubbed(:member_role, role: role_other) }
    let(:user_member_role_inherited_from_other_group) do
      build_stubbed(:member_role, role:, inherited_from: other_group_member_role.id)
    end
    let(:user_member_role_other_inherited_from_other_group) do
      build_stubbed(:member_role, role: role_other, inherited_from: other_group_member_role_other.id)
    end

    context "when group has added to a user a new role and a role that already existed from another group membership" do
      let(:group_member_roles) { [group_member_role, group_member_role_other] }
      let(:user_member_roles) do
        [
          user_member_role_inherited_from_other_group,
          user_member_role_inherited,
          user_member_role_other_inherited
        ]
      end

      include_examples "roles updated"
    end

    context "when group has added to a user some roles that already existed from another group membership" do
      let(:group_member_roles) { [group_member_role, group_member_role_other] }
      let(:user_member_roles) do
        [
          user_member_role_inherited_from_other_group,
          user_member_role_other_inherited_from_other_group,
          user_member_role_inherited,
          user_member_role_other_inherited
        ]
      end

      include_examples "roles unchanged"
    end
  end
end
