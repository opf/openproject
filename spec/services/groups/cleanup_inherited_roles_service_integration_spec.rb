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

describe Groups::CleanupInheritedRolesService, 'integration', type: :model do
  subject(:service_call) do
    member.destroy
    instance.call(params)
  end

  let(:project) { create :project }
  let(:role) { create :role }
  let(:current_user) { create :admin }
  let(:roles) { [role] }
  let(:params) { { message: message } }
  let(:message) { "Some message" }

  let!(:group) do
    create(:group,
                      members: users).tap do |group|
      create(:member,
                        project: project,
                        principal: group,
                        roles: roles)

      ::Groups::AddUsersService
        .new(group, current_user: User.system, contract_class: EmptyContract)
        .call(ids: users.map(&:id))
    end
  end
  let(:users) { create_list :user, 2 }
  let(:member) { Member.find_by(principal: group) }

  let(:instance) do
    described_class.new(group, current_user: current_user)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)

    allow(::OpenProject::Notifications)
      .to receive(:send)
  end

  context 'when having only the group provided roles' do
    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes all memberships the users have had by the group' do
      service_call

      expect(Member.where(principal: users))
        .to be_empty
    end

    it 'sends a notification for the destroyed members' do
      user_members = Member.where(principal: users).to_a

      service_call

      user_members.each do |user_member|
        expect(OpenProject::Notifications)
          .to have_received(:send)
          .with(OpenProject::Events::MEMBER_DESTROYED, member: user_member)
      end
    end

    it 'sends no notifications' do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .not_to have_received(:perform_later)
    end
  end

  context 'when also having own roles' do
    let(:another_role) { create(:role) }
    let!(:first_user_member) do
      group
      Member.find_by(principal: users.first).tap do |m|
        m.roles << another_role
      end
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes all memberships the users have had only by the group' do
      service_call

      expect(Member.where(principal: users.last))
        .to be_empty
    end

    it 'keeps the memberships where project independent roles were assigned' do
      service_call

      expect(first_user_member.updated_at)
        .not_to eql(Member.find_by(id: first_user_member.id).updated_at)

      expect(first_user_member.reload.roles)
        .to match_array([another_role])
    end

    it 'sends a notification on the kept membership' do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with([first_user_member.id],
              message,
              true)
    end
  end

  context 'when the user has had the role added by the group before' do
    let(:another_role) { create(:role) }
    let!(:first_user_member) do
      Member.find_by(principal: users.first).tap do |m|
        m.member_roles.create(role: role)
      end
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes all memberships the users have had only by the group' do
      service_call

      expect(Member.where(principal: users.last))
        .to be_empty
    end

    it 'keeps the memberships where project independent roles were assigned' do
      service_call

      expect(first_user_member.updated_at)
        .not_to eql(Member.find_by(id: first_user_member.id).updated_at)

      expect(first_user_member.reload.roles)
        .to match_array([role])
    end

    it 'sends a notification on the kept membership' do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with([first_user_member.id],
              message,
              true)
    end
  end

  context 'when specifying the member_roles to be removed (e.g. when removing a user from a group)' do
    let(:member_role_ids) do
      MemberRole
        .where(member_id: Member.where(principal: users.first))
        .pluck(:id)
    end
    let(:params) { { member_role_ids: member_role_ids} }

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes memberships associated to the member roles' do
      service_call

      expect(Member.where(principal: users.first))
        .to be_empty
    end

    it 'keeps the memberships not associated to the member roles' do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to match_array([role])
    end

    it 'sends no notifications' do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .not_to have_received(:perform_later)
    end
  end

  context 'when not allowed' do
    let(:current_user) { User.anonymous }

    it 'fails the request' do
      expect(subject).to be_failure
      expect(subject.message).to match /may not be accessed/
    end
  end
end
