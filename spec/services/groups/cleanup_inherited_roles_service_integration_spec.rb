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

RSpec.describe Groups::CleanupInheritedRolesService, "integration", type: :model do
  subject(:service_call) do
    group_members.destroy_all
    instance.call(params)
  end

  shared_let(:current_user) { create(:admin) }
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:, author: current_user) }
  shared_let(:role) { create(:project_role) }
  shared_let(:work_package_role) { create(:view_work_package_role) }
  shared_let(:global_role) { create(:global_role) }

  shared_let(:users) { create_list(:user, 2) }

  shared_let(:roles) { [role] }
  shared_let(:work_package_roles) { [work_package_role] }
  shared_let(:global_roles) { [global_role] }

  shared_let(:group) do
    create(:group,
           members: users,
           global_roles:,
           member_with_roles: { project => roles, work_package => work_package_roles }) do |group|
      Groups::CreateInheritedRolesService
        .new(group, current_user: User.system, contract_class: EmptyContract)
        .call(user_ids: users.map(&:id))
    end
  end

  let(:params) { { message: } }
  let(:message) { "Some message" }
  let(:group_members) { Member.where(principal: group) }

  let(:instance) do
    described_class.new(group, current_user:)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)

    allow(OpenProject::Notifications)
      .to receive(:send)
  end

  context "when having only the group provided roles" do
    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes all memberships the users have had by the group" do
      service_call

      expect(Member.where(principal: users))
        .to be_empty
    end

    it "sends a notification for the destroyed members" do
      user_members = Member.where(principal: users).to_a

      service_call

      user_members.each do |user_member|
        expect(OpenProject::Notifications)
          .to have_received(:send)
          .with(OpenProject::Events::MEMBER_DESTROYED, member: user_member)
      end
    end

    it "sends no notifications" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .not_to have_received(:perform_later)
    end
  end

  context "when also having own roles" do
    shared_let(:another_role) { create(:project_role) }
    shared_let(:another_work_package_role) { create(:comment_work_package_role) }
    shared_let(:another_global_role) { create(:global_role) }
    let!(:first_user_member) do
      Member.find_by(principal: users.first).tap do |m|
        m.roles << another_role
        m.roles << another_work_package_role
        m.roles << another_global_role
      end
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes all memberships that users have had only by the group" do
      service_call

      expect(Member.where(principal: users.last))
        .to be_empty
    end

    it "keeps the memberships where group independent roles were assigned" do
      service_call

      expect(first_user_member.updated_at)
        .not_to eql(Member.find_by(id: first_user_member.id).updated_at)

      expect(first_user_member.reload.roles)
        .to contain_exactly(another_role, another_work_package_role, another_global_role)
    end

    it "sends a notification on the kept membership" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with(current_user,
              [first_user_member.id],
              message,
              true)
    end
  end

  context "when the user has had the roles added by the group before" do
    let!(:first_user_member) do
      Member.find_by(principal: users.first).tap do |m|
        m.member_roles.create(role:)
        m.member_roles.create(role: work_package_role)
        m.member_roles.create(role: global_role)
      end
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes all memberships the users have had only by the group" do
      service_call

      expect(Member.where(principal: users.last))
        .to be_empty
    end

    it "keeps the memberships where group independent roles were assigned" do
      service_call

      expect(first_user_member.updated_at)
        .not_to eql(Member.find_by(id: first_user_member.id).updated_at)

      expect(first_user_member.reload.roles)
        .to contain_exactly(role, work_package_role, global_role)
    end

    it "sends a notification on the kept membership" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with(current_user,
              [first_user_member.id],
              message,
              true)
    end
  end

  context "when specifying the member_roles to be removed (e.g. when removing a user from a group)" do
    let(:member_role_ids) do
      MemberRole
        .where(member_id: Member.where(principal: users.first))
        .pluck(:id)
    end
    let(:params) { { member_role_ids: } }

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes memberships associated to the given member roles" do
      service_call

      expect(Member.where(principal: users.first))
        .to be_empty
    end

    it "keeps the memberships not associated to the given member roles" do
      service_call

      expect(Member.where(principal: users.last).flat_map(&:roles))
        .to contain_exactly(role, work_package_role, global_role)
    end

    it "sends no notifications" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .not_to have_received(:perform_later)
    end
  end

  context "when not allowed" do
    let(:current_user) { User.anonymous }

    it "fails the request" do
      expect(subject).to be_failure
      expect(subject.message).to match /may not be accessed/
    end
  end
end
