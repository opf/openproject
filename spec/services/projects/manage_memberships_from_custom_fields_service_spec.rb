# frozen_string_literal: true

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

RSpec.describe Projects::ManageMembershipsFromCustomFieldsService, type: :model do
  let(:project) { create(:project) }
  let(:project_role) { create(:project_role) }

  let(:admin) { create(:admin) }
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user3) { create(:user) }
  let(:user4) { create(:user) }
  let(:user5) { create(:user) }
  let(:placeholder_user) { create(:placeholder_user) }

  let(:custom_field) do
    create(
      :project_custom_field,
      :user,
      role_id: project_role.id,
      projects: [project]
    )
  end

  let(:instance) do
    described_class.new(
      user: admin,
      project:,
      custom_field:
    )
  end

  subject do
    instance.call(
      old_value: old_users.map { it.id.to_s },
      new_value: new_users.map { it.id.to_s }
    )
  end

  context "when the user is not a member of the project" do
    context "when adding a user to the custom field" do
      let(:old_users) { [] }
      let(:new_users) { [user1] }

      it "adds the user as a member to the project with the role from the custom field" do
        expect do
          subject
        end.to change { project.member_principals.count }.by(1)

        membership = project.member_principals.find_by(principal: user1)
        expect(membership).to be_present
        expect(membership.roles).to contain_exactly(custom_field.role)
      end
    end

    context "when the user is a placeholder user" do
      let(:old_users) { [] }
      let(:new_users) { [placeholder_user] }

      it "adds the placeholder user as a member to the project with the role from the custom field" do
        expect do
          subject
        end.to change { project.member_principals.count }.by(1)

        membership = project.member_principals.find_by(principal: placeholder_user)
        expect(membership).to be_present
        expect(membership.roles).to contain_exactly(custom_field.role)
      end
    end

    context "when removing a user from the custom field" do
      let(:old_users) { [user1] }
      let(:new_users) { [] }

      it "does not change the project membership, and also shows no error" do
        expect do
          subject
        end.not_to change { project.member_principals.count }
      end
    end
  end

  context "when the user is already a member of the project but with different roles" do
    let(:other_role) { create(:project_role) }

    context "when adding a user to the custom field" do
      let!(:membership) { create(:member, project:, principal: user1, roles: [other_role]) }

      let(:old_users) { [] }
      let(:new_users) { [user1] }

      it "adds the role to the membership, but does not create a new one" do
        expect do
          subject
        end.not_to change { project.member_principals.count }

        membership = project.member_principals.find_by(principal: user1)
        expect(membership).to be_present
        expect(membership.roles).to contain_exactly(custom_field.role, other_role)
      end
    end

    context "when removing a user from the custom field" do
      let!(:membership) { create(:member, project:, principal: user1, roles: [other_role, custom_field.role]) }
      let(:old_users) { [user1] }
      let(:new_users) { [] }

      it "removes the role from the membership but keeps the membership" do
        expect do
          subject
        end.not_to change { project.member_principals.count }

        membership = project.member_principals.find_by(principal: user1)
        expect(membership).to be_present
        expect(membership.roles).to contain_exactly(other_role)
      end
    end
  end

  context "when the user is already a member of the project with only the role from the custom field" do
    let!(:membership) { create(:member, project:, principal: user1, roles: [custom_field.role]) }

    context "when adding a user to the custom field" do
      let(:old_users) { [] }
      let(:new_users) { [user1] }

      it "does not change the project membership but also does not return an error" do
        expect do
          subject
        end.not_to change { project.member_principals.count }

        membership = project.member_principals.find_by(principal: user1)
        expect(membership).to be_present
        expect(membership.roles).to contain_exactly(custom_field.role)
      end
    end

    context "when removing a user from the custom field" do
      let(:old_users) { [user1] }
      let(:new_users) { [] }

      it "removes the membership from the project" do
        expect do
          subject
        end.to change { project.member_principals.count }.by(-1)

        membership = project.member_principals.find_by(principal: user1)
        expect(membership).to be_nil
      end
    end
  end

  context "when adding and removing multiple users" do
    let(:other_role) { create(:project_role) }

    let!(:membership_user2) { create(:member, project:, principal: user2, roles: [other_role, custom_field.role]) }
    let!(:membership_user3) { create(:member, project:, principal: user3, roles: [custom_field.role]) }
    let!(:membership_user4) { create(:member, project:, principal: user4, roles: [custom_field.role]) }
    let!(:membership_user5) { create(:member, project:, principal: user5, roles: [other_role]) }

    let(:old_users) { [user2, user3, user4] }
    let(:new_users) { [user1, user3, user5] }

    it "adds and removes the correct users" do
      subject

      # user 1 is added as a new member
      membership1 = project.member_principals.find_by(principal: user1)
      expect(membership1).to be_present
      expect(membership1.roles).to contain_exactly(custom_field.role)

      # user 2 gets one role removed but is still a member due to other roles
      membership2 = project.member_principals.find_by(principal: user2)
      expect(membership2).to be_present
      expect(membership2.roles).to contain_exactly(other_role)

      # user 3 remains unchanged
      membership3 = project.member_principals.find_by(principal: user3)
      expect(membership3).to be_present
      expect(membership3.roles).to contain_exactly(custom_field.role)

      # user 4 is removed entirely
      membership4 = project.member_principals.find_by(principal: user4)
      expect(membership4).to be_nil

      # user 5 gets the role added
      membership5 = project.member_principals.find_by(principal: user5)
      expect(membership5).to be_present
      expect(membership5.roles).to contain_exactly(other_role, custom_field.role)
    end
  end
end
