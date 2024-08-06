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

RSpec.describe Groups::UpdateRolesService, "integration", type: :model do
  subject(:service_call) { instance.call(member:, message:, send_notifications:) }

  shared_let(:project) { create(:project) }
  shared_let(:current_user) { create(:admin) }
  shared_let(:users) { create_list(:user, 2) }

  shared_let(:role) { create(:project_role) }
  let(:roles) { [role] }

  let!(:group) do
    create(:group,
           members: users).tap do |group|
      create(:member,
             project:,
             principal: group,
             roles:)

      Groups::CreateInheritedRolesService
        .new(group, current_user: User.system, contract_class: EmptyContract)
        .call(user_ids: users.map(&:id), send_notifications: false)
    end
  end

  let(:member) { Member.find_by(principal: group) }
  let(:message) { "Some message" }
  let(:send_notifications) { true }

  let(:instance) do
    described_class.new(group, current_user:)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)
  end

  shared_examples_for "keeps timestamp" do
    specify "updated_at on member is unchanged" do
      expect { service_call }
        .not_to(change { Member.find_by(principal: user).updated_at })
    end
  end

  shared_examples_for "updates timestamp" do
    specify "updated_at on member is changed" do
      expect { service_call }
        .to(change { Member.find_by(principal: user).updated_at })
    end
  end

  shared_examples_for "sends notification" do
    specify "on the updated membership" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
        .with(current_user,
              a_collection_containing_exactly(*Member.where(principal: user).pluck(:id)),
              message,
              true)
    end
  end

  shared_examples_for "sends no notification" do
    specify "on the updated membership" do
      service_call

      expect(Notifications::GroupMemberAlteredJob)
        .not_to have_received(:perform_later)
    end
  end

  context "when adding a role" do
    shared_let(:added_role) { create(:project_role) }

    before do
      member.roles << added_role
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "adds the roles to all inherited memberships" do
      service_call

      Member.where(principal: users).find_each do |member|
        expect(member.roles)
          .to contain_exactly(role, added_role)
      end
    end

    it_behaves_like "sends notification" do
      let(:user) { users }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "with global membership" do
    shared_let(:role) { create(:global_role) }
    let!(:group) do
      create(:group,
             members: users).tap do |group|
        create(:global_member,
               principal: group,
               roles:)

        Groups::CreateInheritedRolesService
          .new(group, current_user: User.system, contract_class: EmptyContract)
          .call(user_ids: users.map(&:id))
      end
    end

    context "when adding a global role" do
      shared_let(:added_role) { create(:global_role) }

      before do
        member.roles << added_role
      end

      it "is successful" do
        expect(service_call)
          .to be_success
      end

      it "adds the roles to all inherited memberships" do
        service_call

        Member.where(principal: users).find_each do |member|
          expect(member.roles)
            .to contain_exactly(role, added_role)
        end
      end

      it_behaves_like "sends notification" do
        let(:user) { users }
      end

      context "when notifications are suppressed" do
        let(:send_notifications) { false }

        it_behaves_like "sends no notification"
      end
    end

    context "when removing a global role" do
      shared_let(:global_role) { create(:global_role) }
      let(:roles) { [role, global_role] }

      before do
        member.roles = [role]
      end

      it "is successful" do
        expect(service_call)
          .to be_success
      end

      it "removes the roles from all inherited memberships" do
        service_call

        Member.where(principal: users).find_each do |member|
          expect(member.roles)
            .to contain_exactly(role)
        end
      end

      it_behaves_like "sends notification" do
        let(:user) { users }
      end

      context "when notifications are suppressed" do
        let(:send_notifications) { false }

        it_behaves_like "sends no notification"
      end
    end
  end

  context "when adding a role but with one user having had the role before (no inherited from)" do
    shared_let(:added_role) { create(:project_role) }

    before do
      member.roles << added_role

      Member.where(principal: users.first).first.member_roles.create(role: added_role)
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "keeps the roles unchanged for those user that already had the role" do
      service_call

      expect(Member.find_by(principal: users.first).roles.uniq)
        .to contain_exactly(role, added_role)
    end

    it "adds the roles to all inherited memberships" do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to contain_exactly(role, added_role)
    end

    it_behaves_like "keeps timestamp" do
      let(:user) { users.first }
    end

    it_behaves_like "updates timestamp" do
      let(:user) { users.last }
    end

    it_behaves_like "sends notification" do
      let(:user) { users.last }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when removing a role" do
    shared_let(:role_to_remove) { create(:project_role) }
    let(:roles) { [role, role_to_remove] }

    before do
      member.roles = [role]
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes the roles from all inherited memberships" do
      service_call

      Member.where(principal: users).find_each do |member|
        expect(member.roles)
          .to contain_exactly(role)
      end
    end

    it_behaves_like "sends notification" do
      let(:user) { users }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when removing a role but with a user having had the role before (no inherited_from)" do
    shared_let(:role_to_remove) { create(:project_role) }
    let(:roles) { [role, role_to_remove] }

    before do
      member.roles = [role]

      # Behaves as if the user had that role before the role's membership was created
      Member.find_by(principal: users.first).member_roles.create(role: role_to_remove)
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "removes the inherited roles" do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to contain_exactly(role)
    end

    it "keeps the non inherited roles" do
      service_call

      expect(Member.find_by(principal: users.first).roles)
        .to contain_exactly(role, role_to_remove)
    end

    it_behaves_like "keeps timestamp" do
      let(:user) { users.first }
    end

    it_behaves_like "updates timestamp" do
      let(:user) { users.last }
    end

    it_behaves_like "sends notification" do
      let(:user) { users.last }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when replacing roles" do
    shared_let(:replacement_role) { create(:project_role) }

    before do
      member.roles = [replacement_role]
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "replaces the role in all user memberships" do
      service_call

      Member.where(principal: users).find_each do |member|
        expect(member.roles)
          .to contain_exactly(replacement_role)
      end
    end

    it_behaves_like "sends notification" do
      let(:user) { users }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when replacing a role but with a user having had the replaced role before (no inherited_from)" do
    shared_let(:replacement_role) { create(:project_role) }

    before do
      member.roles = [replacement_role]

      # Behaves as if the user had the role being replaced before the role's membership was created
      Member.where(principal: users.first).first.member_roles.create(role:)
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "replaces the inherited role" do
      service_call

      expect(Member.find_by(principal: users.last).roles)
        .to contain_exactly(replacement_role)
    end

    it "keeps the non inherited roles" do
      service_call

      expect(Member.find_by(principal: users.first).roles)
        .to contain_exactly(role, replacement_role)
    end

    it_behaves_like "updates timestamp" do
      let(:user) { users.first }
    end

    it_behaves_like "updates timestamp" do
      let(:user) { users.last }
    end

    it_behaves_like "sends notification" do
      let(:user) { users }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when adding a role and the user has a role already granted by a different group" do
    shared_let(:other_role) { create(:project_role) }

    let!(:second_group) do
      create(:group,
             members: users).tap do |group|
        create(:member,
               project:,
               principal: group,
               roles: [other_role])

        Groups::CreateInheritedRolesService
          .new(group, current_user: User.system, contract_class: EmptyContract)
          .call(user_ids: users.map(&:id), send_notifications: false)
      end
    end

    shared_let(:users) { [create(:user)] }
    shared_let(:added_role) { create(:project_role) }

    before do
      member.roles << added_role
    end

    it "is successful" do
      expect(service_call)
        .to be_success
    end

    it "keeps the roles the user already had before and adds the new one" do
      service_call

      expect(Member.find_by(principal: users.first).roles.uniq)
        .to contain_exactly(role, other_role, added_role)
    end

    it_behaves_like "sends notification" do
      let(:user) { users }
    end

    context "when notifications are suppressed" do
      let(:send_notifications) { false }

      it_behaves_like "sends no notification"
    end
  end

  context "when not allowed" do
    shared_let(:current_user) { User.anonymous }

    it "fails the request" do
      expect(subject).to be_failure
      expect(subject.message).to match /may not be accessed/
    end
  end
end
