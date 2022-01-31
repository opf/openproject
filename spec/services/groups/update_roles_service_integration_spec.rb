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

describe Groups::UpdateRolesService, 'integration', type: :model do
  subject(:service_call) { instance.call(member: member, message: message) }

  let(:project) { create :project }
  let(:role) { create :role }
  let(:current_user) { create :admin }
  let(:roles) { [role] }

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
  let(:message) { "Some message" }

  let(:instance) do
    described_class.new(group, current_user: current_user)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)
  end

  shared_examples_for 'keeps timestamp' do
    it 'updated_at on member is unchanged' do
      expect { service_call }
        .not_to change { Member.find_by(principal: user).updated_at }
    end
  end

  shared_examples_for 'updates timestamp' do
    it 'updated_at on member is changed' do
      expect { service_call }
        .to change { Member.find_by(principal: user).updated_at }
    end
  end

  shared_examples_for 'sends notification' do
    it 'on the updated membership' do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with(a_collection_containing_exactly(*Member.where(principal: user).pluck(:id)),
              message,
              true)
    end
  end

  context 'when adding a role' do
    let(:added_role) { create(:role) }

    before do
      member.roles << added_role
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'adds the roles to all inherited memberships' do
      service_call

      Member.where(principal: users).each do |member|
        expect(member.roles)
          .to match_array([role, added_role])
      end
    end

    it_behaves_like 'sends notification' do
      let(:user) { users }
    end
  end

  context 'when adding a role but with one user having had the role before (no inherited from)' do
    let(:added_role) { create(:role) }

    before do
      member.roles << added_role

      Member.where(principal: users.first).first.member_roles.create(role: added_role)
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'keeps the roles unchanged for those user that already had the role' do
      service_call

      expect(Member.find_by(principal: users.first).roles.uniq)
        .to match_array([role, added_role])
    end

    it 'adds the roles to all inherited memberships' do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to match_array([role, added_role])
    end

    it_behaves_like 'keeps timestamp' do
      let(:user) { users.first }
    end

    it_behaves_like 'updates timestamp' do
      let(:user) { users.last }
    end

    it_behaves_like 'sends notification' do
      let(:user) { users.last }
    end
  end

  context 'when removing a role' do
    let(:roles) { [role, create(:role)] }

    before do
      member.roles = [role]
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes the roles from all inherited memberships' do
      service_call

      Member.where(principal: users).each do |member|
        expect(member.roles)
          .to match_array([role])
      end
    end

    it_behaves_like 'sends notification' do
      let(:user) { users }
    end
  end

  context 'when removing a role but with a user having had the role before (no inherited_from)' do
    let(:roles) { [role, create(:role)] }

    before do
      member.roles = [role]

      # Behaves as if the user had that role before the role's membership was created
      Member.find_by(principal: users.first).member_roles.create(role: roles.last)
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'removes the inherited roles' do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to match_array([role])
    end

    it 'keeps the non inherited roles' do
      service_call

      expect(Member.find_by(principal: users.first).roles)
        .to match_array(roles)
    end

    it_behaves_like 'keeps timestamp' do
      let(:user) { users.first }
    end

    it_behaves_like 'updates timestamp' do
      let(:user) { users.last }
    end

    it_behaves_like 'sends notification' do
      let(:user) { users.last }
    end
  end

  context 'when replacing roles' do
    let(:replacement_role) { create(:role) }

    before do
      member.roles = [replacement_role]
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'replaces the role in all user memberships' do
      service_call

      Member.where(principal: users).each do |member|
        expect(member.roles)
          .to match_array([replacement_role])
      end
    end

    it_behaves_like 'sends notification' do
      let(:user) { users }
    end
  end

  context 'when replacing a role but with a user having had the replaced role before (no inherited_from)' do
    let(:replacement_role) { create(:role) }

    before do
      member.roles = [replacement_role]

      # Behaves as if the user had that role before the role's membership was created
      Member.where(principal: users.first).first.member_roles.create(role: roles.last)
    end

    it 'is successful' do
      expect(service_call)
        .to be_success
    end

    it 'replaces the inherited role' do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to match_array([replacement_role])
    end

    it 'keeps the non inherited roles' do
      service_call

      expect(Member.find_by(principal: users.first).roles)
        .to match_array(roles + [replacement_role])
    end

    it_behaves_like 'updates timestamp' do
      let(:user) { users.first }
    end

    it_behaves_like 'updates timestamp' do
      let(:user) { users.last }
    end

    it_behaves_like 'sends notification' do
      let(:user) { users }
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
