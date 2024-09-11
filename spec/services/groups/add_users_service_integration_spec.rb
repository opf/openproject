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

RSpec.describe Groups::AddUsersService, "integration" do
  subject(:service_call) { instance.call(ids: user_ids, message:) }

  let(:projects) { create_list(:project, 2) }
  let(:role) { create(:project_role) }
  let(:admin) { create(:admin) }

  let!(:group) do
    create(:group, member_with_roles: projects.zip([role].cycle).to_h)
  end

  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:user_ids) { [user1.id, user2.id] }
  let(:message) { "Some message" }

  let(:instance) do
    described_class.new(group, current_user:)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)
  end

  shared_examples_for "adds the users to the group and project" do
    it "adds the users to the group and project" do
      expect(service_call).to be_success

      expect(group.users)
        .to contain_exactly(user1, user2)
      expect(user1.memberships.where(project_id: projects).count).to eq 2
      expect(user1.memberships.map(&:roles).flatten).to contain_exactly(role, role)
      expect(user2.memberships.where(project_id: projects).count).to eq 2
      expect(user2.memberships.map(&:roles).flatten).to contain_exactly(role, role)
    end
  end

  shared_examples_for "sends notification" do
    it "on the updated membership" do
      service_call

      ids = defined?(members) ? members : Member.where(principal: user).pluck(:id)

      expect(Notifications::GroupMemberAlteredJob)
        .to have_received(:perform_later)
              .with(current_user,
                    a_collection_containing_exactly(*ids),
                    message,
                    true)
    end
  end

  context "when an admin user" do
    let(:current_user) { admin }

    it_behaves_like "adds the users to the group and project"

    it_behaves_like "sends notification" do
      let(:user) { user_ids }
    end

    context "when the group is invalid (e.g. required cf not set)" do
      before do
        group
        # The group is now invalid as it has no cv for this field
        create(:custom_field, type: "GroupCustomField", is_required: true, field_format: "int")
      end

      it_behaves_like "adds the users to the group and project"

      it_behaves_like "sends notification" do
        let(:user) { user_ids }
      end
    end

    context "when the user was already a member in a project with the same role" do
      let(:previous_project) { projects.first }
      let!(:user_member) do
        create(:member,
               project: previous_project,
               roles: [role],
               principal: user1)
      end

      it_behaves_like "adds the users to the group and project"

      it "does not update the timestamps on the preexisting membership" do
        # Need to reload so that the timestamps are set by the database
        user_member.reload

        service_call

        expect(Member.find(user_member.id).updated_at)
          .to eql(user_member.updated_at)
      end

      it_behaves_like "sends notification" do
        let(:members) do
          Member.where(user_id: user_ids).where.not(id: user_member).pluck(:id)
        end
      end
    end

    context "when the user was already a member in a project with only one role the group adds" do
      let(:project) { create(:project) }
      let(:roles) { create_list(:project_role, 2) }
      let!(:group) do
        create(:group, member_with_roles: { project => roles })
      end
      let!(:user_member) do
        create(:member, project:, roles: [roles.first], principal: user1)
      end

      it "adds the users to the group and project" do
        expect(service_call).to be_success

        expect(group.users)
          .to contain_exactly(user1, user2)
        expect(user1.memberships.where(project_id: project).map(&:roles).flatten)
          .to match_array(roles)
        expect(user2.memberships.where(project_id: project).count).to eq 1
        expect(user2.memberships.map(&:roles).flatten).to match_array roles
      end

      it "updates the timestamps on the preexisting membership" do
        service_call

        expect(Member.find(user_member.id).updated_at)
          .not_to eql(user_member.updated_at)
      end

      it_behaves_like "sends notification" do
        let(:user) { user_ids }
      end
    end

    context "when the user was already a member in a project with a different role" do
      let(:other_role) { create(:project_role) }
      let(:previous_project) { projects.first }
      let!(:user_member) do
        create(:member,
               project: previous_project,
               roles: [other_role],
               principal: user1)
      end

      it "adds the users to the group and project" do
        expect(service_call).to be_success

        expect(group.users)
          .to contain_exactly(user1, user2)
        expect(user1.memberships.where(project_id: previous_project).map(&:roles).flatten)
          .to contain_exactly(role, other_role)
        expect(user1.memberships.where(project_id: projects.last).map(&:roles).flatten)
          .to contain_exactly(role)
        expect(user2.memberships.where(project_id: projects).count).to eq 2
        expect(user2.memberships.map(&:roles).flatten).to contain_exactly(role, role)
      end

      it "updates the timestamps on the preexisting membership" do
        service_call

        expect(Member.find(user_member.id).updated_at)
          .not_to eql(user_member.updated_at)
      end

      it_behaves_like "sends notification" do
        let(:user) { user_ids }
      end
    end

    context "with global role" do
      let(:role) { create(:global_role, permissions: [:add_project]) }
      let!(:group) do
        create(:group, global_roles: [role])
      end

      it "adds the users to the group and their membership to the global role" do
        expect(service_call).to be_success

        expect(group.users).to contain_exactly(user1, user2)
        expect(user1.memberships.where(project_id: nil).count).to eq 1
        expect(user1.memberships.flat_map(&:roles)).to contain_exactly(role)
        expect(user2.memberships.where(project_id: nil).count).to eq 1
        expect(user2.memberships.flat_map(&:roles)).to contain_exactly(role)
      end

      context "when one user already has a global role that the group would add" do
        let(:global_roles) { create_list(:global_role, 2) }
        let!(:group) do
          create(:group, global_roles:)
        end
        let!(:user_membership) do
          create(:member, project: nil, roles: [global_roles.first], principal: user1)
        end

        it "adds their membership to the global role" do
          expect(service_call).to be_success

          expect(user1.memberships.where(project_id: nil).flat_map(&:roles)).to match_array global_roles
          expect(user2.memberships.flat_map(&:roles)).to match_array global_roles
        end
      end
    end
  end

  context "when not allowed" do
    let(:current_user) { User.anonymous }

    it "fails the request" do
      expect(service_call).to be_failure
      expect(service_call.message).to match /may not be accessed/
    end
  end
end
