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

RSpec.describe Roles::DeleteService, "integration", type: :model do
  subject(:service_call) { described_class.new(user: current_user, model: role).call }

  shared_let(:current_user) { create(:admin) }

  before do
    allow(OpenProject::Notifications).to receive(:send)
  end

  context "when the role is not attributed to anybody" do
    let!(:role) { create(:project_role) }

    it "destroys the role" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)
    end
  end

  context "when the role is builtin" do
    let!(:role) { create(:non_member) }

    it "keeps the role" do
      expect(service_call).to be_failure

      expect(Role).to exist(role.id)
    end
  end

  context "when a member has the role and another role" do
    let!(:project) { create(:project) }
    let!(:role) { create(:project_role) }
    let!(:other_role) { create(:project_role) }
    let!(:user) { create(:user, member_with_roles: { project => [role, other_role] }) }

    it "destroys the role and keeps the membership with its remaining role" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)

      member = Member.find_by(principal: user, project:)
      expect(member.roles).to contain_exactly(other_role)
    end
  end

  context "when the role is the only one a member has in the project" do
    let!(:project) { create(:project) }
    let!(:role) { create(:project_role) }
    let!(:user) { create(:user, member_with_roles: { project => [role] }) }

    it "destroys the role and the membership" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)
      expect(Member.where(principal: user, project:)).to be_empty
    end

    it "sends a notification for the destroyed membership" do
      member = Member.find_by(principal: user, project:)

      service_call

      expect(OpenProject::Notifications)
        .to have_received(:send)
        .with(OpenProject::Events::MEMBER_DESTROYED, member:)
    end
  end

  context "when the role is only used in an archived project" do
    let!(:project) { create(:project, active: false) }
    let!(:role) { create(:project_role) }
    let!(:user) { create(:user, member_with_roles: { project => [role] }) }

    it "destroys the role and the membership" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)
      expect(Member.where(principal: user, project:)).to be_empty
    end
  end

  context "when a group grants the role" do
    let!(:project) { create(:project) }
    let!(:role) { create(:project_role) }
    let!(:users) { create_list(:user, 2) }
    let!(:group) do
      create(:group, members: users, member_with_roles: { project => [role] }) do |group|
        Groups::CreateInheritedRolesService
          .new(group, current_user: User.system, contract_class: EmptyContract)
          .call(user_ids: users.map(&:id))
      end
    end

    it "destroys the role, the group membership and the inherited memberships" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)
      expect(Member.where(principal: [group, *users], project:)).to be_empty
    end

    context "and a user holds another role of their own" do
      let!(:other_role) { create(:project_role) }

      before do
        Member.find_by(principal: users.first, project:).roles << other_role
      end

      it "keeps that membership with the remaining role" do
        expect(service_call).to be_success

        expect(Member.find_by(principal: users.first, project:).roles)
          .to contain_exactly(other_role)
        expect(Member.where(principal: [group, users.second], project:)).to be_empty
      end
    end

    context "and a user additionally holds the same role directly" do
      before do
        Member.find_by(principal: users.first, project:).member_roles.create!(role:)
      end

      it "destroys the membership as no other role remains" do
        expect(service_call).to be_success

        expect(Member.where(principal: [group, *users], project:)).to be_empty
      end
    end
  end

  context "when the role is a global role" do
    let!(:project) { create(:project) }
    let!(:project_role) { create(:project_role) }
    let!(:role) { create(:global_role) }
    let!(:user) do
      create(:user, global_roles: [role], member_with_roles: { project => [project_role] })
    end

    it "destroys the role and the global membership while keeping the project membership" do
      expect(service_call).to be_success

      expect(Role).not_to exist(role.id)
      expect(Member.where(principal: user, project: nil)).to be_empty
      expect(Member.find_by(principal: user, project:).roles).to contain_exactly(project_role)
    end

    context "and the user holds another global role" do
      let!(:other_global_role) { create(:global_role) }
      let!(:user) do
        create(:user, global_roles: [role, other_global_role])
      end

      it "keeps the global membership with its remaining role" do
        expect(service_call).to be_success

        expect(Member.find_by(principal: user, project: nil).roles)
          .to contain_exactly(other_global_role)
      end
    end
  end
end
