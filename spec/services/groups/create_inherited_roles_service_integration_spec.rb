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

RSpec.describe Groups::CreateInheritedRolesService, "integration" do
  # The setup for these specs are a bit weird. First, the group is set up with its users already
  # attached. Then, the memberships of the group are added afterwards.
  # That way, the inherited roles are not yet created which they would otherwise by the group factory.
  # This mimicks have a group with users already set up which can happen in two cases:
  # * The Groups::AddUsersService service has run before because an additional user has been added to the group.
  #   The AddUsersService then calls the CreateInheritedRolesService
  # * The group receives an additional membership (in a project)
  # The setup reflects both cases at the same time.
  subject(:service_call) { instance.call(user_ids:, project_ids:, message:) }

  shared_let(:project1) { create(:project) }
  shared_let(:project2) { create(:project) }
  shared_let(:user1) { create(:user) }
  shared_let(:user2) { create(:user) }
  shared_let(:role1) { create(:project_role) }
  shared_let(:admin) { create(:admin) }

  let(:group_projects) { [project1, project2] }
  let(:group_roles) { [role1] }
  let(:group_users) { [user1, user2] }

  let!(:group) do
    create(:group).tap do |g|
      # Setting up the user being part of the group without triggering the inherited roles
      # to be assigned before the test is actually run.
      group_users.each do |u|
        GroupUser.create group: g, user: u
      end

      group_projects.each do |gp|
        create(:member,
               principal: g,
               roles: group_roles,
               project: gp)
      end
    end
  end

  let(:user_ids) { group_users.map(&:id) }
  let(:project_ids) { group_projects.map(&:id) }
  let(:message) { "Some message" }
  let(:current_user) { admin }

  let(:instance) do
    described_class.new(group, current_user:)
  end

  before do
    allow(Notifications::GroupMemberAlteredJob)
      .to receive(:perform_later)
  end

  shared_examples_for "inherits the roles of the group to the users" do
    it "inherits the roles of the group to the users" do
      expect(service_call).to be_success

      user_ids.each do |user_id|
        expect(Member.where(project_id: project_ids, user_id:).count)
          .to eq group_projects.count
        expect(Member.where(project_id: project_ids, user_id:).map(&:roles).flatten)
          .to match_array group_projects.count.times.map { group_roles }.flatten
      end
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

  it_behaves_like "inherits the roles of the group to the users"

  it_behaves_like "sends notification" do
    let(:user) { user_ids }
  end

  context "when the group is invalid (e.g. required cf not set)" do
    before do
      group
      # The group is now invalid as it has no cv for this field
      create(:custom_field, type: "GroupCustomField", is_required: true, field_format: "int")
    end

    it_behaves_like "inherits the roles of the group to the users"

    it_behaves_like "sends notification" do
      let(:user) { user_ids }
    end
  end

  context "when the user was already a member in a project with the same role" do
    let(:previous_project) { group_projects.first }
    let!(:user_member) do
      create(:member,
             project: previous_project,
             roles: group_roles,
             principal: user1)
    end

    it_behaves_like "inherits the roles of the group to the users"

    it "does not update the timestamps on the preexisting membership" do
      # Need to reload so that the timestamps are set by the database
      user_member.reload

      service_call

      expect(Member.find(user_member.id).updated_at)
        .to eql(user_member.updated_at)
    end

    it_behaves_like "sends notification" do
      # But only to the user that wasn't a member yet.
      let(:members) do
        Member.where(user_id: user_ids).where.not(id: user_member).pluck(:id)
      end
    end
  end

  context "when the user was already a member in a project with only one role the group adds" do
    let(:group_roles) { create_list(:project_role, 2) }
    let!(:user_member) do
      create(:member,
             project: group_projects.first,
             roles: [group_roles.first],
             principal: user1)
    end

    it_behaves_like "inherits the roles of the group to the users"

    it "updates the timestamps on the preexisting membership" do
      service_call

      expect(Member.find(user_member.id).updated_at)
        .not_to eql(user_member.updated_at)
    end

    it_behaves_like "sends notification" do
      let(:user) { user_ids }
    end
  end

  context "when a user was already a member in a project with a different role" do
    let(:other_role) { create(:project_role) }
    let(:previous_project) { group_projects.first }
    let!(:user_member) do
      create(:member,
             project: previous_project,
             roles: [other_role],
             principal: user1)
    end

    it "inherits the roles of the group to the users" do
      expect(service_call).to be_success

      user_ids.each do |user_id|
        expect(Member.where(project_id: project_ids, user_id:).count)
          .to eq group_projects.count
      end

      expect(Member.where(project_id: previous_project, user_id: user1.id).map(&:roles).flatten)
        .to match_array [group_roles, other_role].flatten
      expect(Member.where(project_id: group_projects - [previous_project], user_id: user1.id).map(&:roles).flatten)
        .to match_array [group_roles].flatten
      expect(Member.where(project_id: project_ids, user_id: user2.id).map(&:roles).flatten)
        .to match_array group_projects.count.times.map { group_roles }.flatten
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
    let(:group_roles) { [create(:global_role)] }
    let(:group_projects) { [] }
    let(:project_ids) { nil }
    let!(:group_member) { create(:global_member, principal: group, roles: group_roles) }

    it "inherits the roles of the group to the users" do
      expect(service_call).to be_success

      expect(user1.memberships.where(project_id: nil).count).to eq 1
      expect(user1.memberships.flat_map(&:roles)).to match_array group_roles
      expect(user2.memberships.where(project_id: nil).count).to eq 1
      expect(user2.memberships.flat_map(&:roles)).to match_array group_roles
    end
  end

  context "with limiting the user and project to create the roles in" do
    let(:added_project) { group_projects.first }
    let(:ignored_project) { group_projects.last }
    let(:added_user) { user_ids.first }
    let(:ignored_user) { user_ids.last }

    subject(:service_call) { instance.call(user_ids: [added_user], message:, project_ids: added_project.id) }

    it "adds the roles to users of the group for the project specified", :aggregate_failure do
      expect(service_call).to be_success

      # Adds the role for the user and project specified
      expect(Member.where(user_id: added_user, project: added_project).count).to eq 1
      expect(Member.where(user_id: added_user, project: added_project).flat_map(&:roles))
        .to match_array group_roles

      # Does not add the role to a user not specified
      expect(Member.where(user_id: ignored_user, project: added_project))
        .not_to exist

      # Does not add the role to a project not specified
      expect(Member.where(user_id: added_user, project: ignored_project))
        .not_to exist
    end
  end

  context "with a role that was granted to a specific entity" do
    let(:project_ids) { nil }
    let(:group_projects) { [] }
    let(:work_package) { create(:work_package, project: project1) }
    let!(:group_membership) { create(:member, principal: group, project: project1, entity: work_package, roles: [role1]) }

    it "inherits the roles of the group to the users also bound to the entity" do
      expect do
        expect(service_call).to be_success
      end.to change(Member.where(project_id: work_package.project_id, entity: work_package), :count).by(user_ids.count)
    end
  end

  context "when not an admin" do
    let(:current_user) { User.anonymous }

    it "fails the request" do
      expect(service_call).to be_failure
      expect(service_call.message).to match /may not be accessed/
    end
  end
end
