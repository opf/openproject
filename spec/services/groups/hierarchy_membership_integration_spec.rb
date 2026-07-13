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

# Integration tests for membership propagation through group hierarchies.
#
# The hierarchy under test (unless a specific test sets up its own):
#
#   root_group
#     └── mid_group
#           └── leaf_group
#
# Each group has one exclusive direct member:
#   root_user ∈ root_group, mid_user ∈ mid_group, leaf_user ∈ leaf_group
#
RSpec.describe "Group hierarchy membership propagation", type: :model do
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }
  let(:role) { create(:project_role) }
  let(:root_user) { create(:user) }
  let(:mid_user) { create(:user) }
  let(:leaf_user) { create(:user) }

  before do
    allow(Notifications::GroupMemberAlteredJob).to receive(:perform_later)
  end

  # ---------------------------------------------------------------------------
  # Members::CreateService — Making a group a member of a project should
  #                          propagate the membership to all users in the subtree
  # ---------------------------------------------------------------------------

  describe "Members::CreateService" do
    let!(:root_group) { create(:group, members: [root_user]) }
    let!(:mid_group)  { create(:group, members: [mid_user], parent: root_group) }
    let!(:leaf_group) { create(:group, members: [leaf_user], parent: mid_group) }

    it "propagates the membership to all members in the subtree when given to the root group" do
      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      expect(root_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "only propagates to the subtree of the group receiving the membership, not to ancestors" do
      Members::CreateService
        .new(user: admin)
        .call(principal: mid_group, project_id: project.id, role_ids: [role.id])

      expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(root_user.memberships.find_by(project:)).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # Members::UpdateService — changing roles on a group membership updates all subtree members
  # ---------------------------------------------------------------------------

  describe "Members::UpdateService" do
    let!(:root_group) { create(:group, members: [root_user]) }
    let!(:mid_group)  { create(:group, members: [mid_user], parent: root_group) }
    let!(:leaf_group) { create(:group, members: [leaf_user], parent: mid_group) }

    let(:second_role) { create(:project_role) }

    it "updates the inherited roles for all members in the hierarchy when the root group's membership changes" do
      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      group_member = Member.find_by!(principal: root_group, project:)

      Members::UpdateService
        .new(user: admin, model: group_member)
        .call(role_ids: [role.id, second_role.id])

      expect(root_user.memberships.find_by(project:).roles).to contain_exactly(role, second_role)
      expect(mid_user.memberships.find_by(project:).roles).to contain_exactly(role, second_role)
      expect(leaf_user.memberships.find_by(project:).roles).to contain_exactly(role, second_role)
    end
  end

  # ---------------------------------------------------------------------------
  # Groups::AddUsersService — adding a user to a group also inherits ancestor memberships
  # ---------------------------------------------------------------------------

  describe "Groups::AddUsersService" do
    let!(:new_user) { create(:user) }

    it "gives a newly added leaf-group member the memberships inherited from all ancestor groups" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      leaf_group = create(:group, parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::AddUsersService
        .new(leaf_group, current_user: admin)
        .call(ids: [new_user.id], message: nil)

      expect(new_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "gives a newly added mid-group member the memberships inherited from the root group" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, parent: root_group)
      create(:group, parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::AddUsersService
        .new(mid_group, current_user: admin)
        .call(ids: [new_user.id], message: nil)

      expect(new_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "does not inherit ancestor memberships for a user added to the root (no ancestors exist)" do
      root_group = create(:group)
      mid_group  = create(:group, parent: root_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: mid_group, project_id: project.id, role_ids: [role.id])

      Groups::AddUsersService
        .new(root_group, current_user: admin)
        .call(ids: [new_user.id], message: nil)

      expect(new_user.memberships.find_by(project:)).to be_nil
    end
  end

  # ---------------------------------------------------------------------------
  # Groups::UpdateService — removing a user cleans up ancestor-inherited memberships
  # ---------------------------------------------------------------------------

  describe "Groups::UpdateService — user removal" do
    it "removes the ancestor-inherited memberships when a user is removed from a leaf group" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      leaf_group = create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: leaf_group)
        .call(remove_user_ids: [leaf_user.id])

      expect(leaf_user.memberships.find_by(project:)).to be_nil
    end

    it "does not affect other group members when a user is removed from a leaf group" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      leaf_group = create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: leaf_group)
        .call(remove_user_ids: [leaf_user.id])

      expect(root_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "retains the inherited membership when the removed user still belongs to an ancestor group" do
      shared_user = create(:user)
      root_group  = create(:group, members: [shared_user])
      mid_group   = create(:group, parent: root_group)
      leaf_group  = create(:group, parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      # Also add shared_user to leaf_group directly
      Groups::AddUsersService
        .new(leaf_group, current_user: admin)
        .call(ids: [shared_user.id], message: nil)

      Groups::UpdateService
        .new(user: admin, model: leaf_group)
        .call(remove_user_ids: [shared_user.id])

      # shared_user is still in root_group, so the membership must be retained
      expect(shared_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "removes ancestor-inherited memberships when a user is removed from an intermediate group" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      # Removing mid_user from mid_group should also clean up the root-inherited membership
      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(remove_user_ids: [mid_user.id])

      expect(mid_user.memberships.find_by(project:)).to be_nil
      # leaf_user is unaffected — still inherits from root via the hierarchy
      expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end
  end

  # ---------------------------------------------------------------------------
  # Groups::UpdateService — changing the parent propagates/cleans up memberships
  # ---------------------------------------------------------------------------

  describe "Groups::UpdateService — parent change" do
    it "removes the root-inherited memberships from mid and leaf users when the parent link is broken" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: nil)

      expect(mid_user.memberships.find_by(project:)).to be_nil
      expect(leaf_user.memberships.find_by(project:)).to be_nil
    end

    it "keeps the root user's membership intact when the parent link of a child is broken" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: nil)

      expect(root_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "does not remove memberships from users who still belong to the former ancestor directly" do
      shared_user = create(:user)
      root_group  = create(:group, members: [shared_user])
      mid_group   = create(:group, members: [shared_user], parent: root_group)
      create(:group, parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: nil)

      # shared_user is still directly in root_group, so their membership must survive
      expect(shared_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "propagates the new parent's memberships to all users in the subtree when a parent is assigned" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user])
      create(:group, members: [leaf_user], parent: mid_group)
      # leaf is under mid, but mid has no parent yet

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: root_group.id)

      expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
      expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end

    it "does not assign the new parent's memberships to users in unrelated groups" do
      other_user  = create(:user)
      root_group  = create(:group)
      mid_group   = create(:group, members: [mid_user])
      create(:group, members: [other_user])

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      # Connect mid_group to root_group — other_group is unrelated and must not be affected
      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: root_group.id)

      expect(other_user.memberships.find_by(project:)).to be_nil
    end

    it "swaps inherited memberships when a group is re-parented from one root to another" do
      old_role   = create(:project_role)
      new_role   = create(:project_role)
      old_root   = create(:group)
      new_root   = create(:group)
      mid_group  = create(:group, members: [mid_user], parent: old_root)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: old_root, project_id: project.id, role_ids: [old_role.id])
      Members::CreateService
        .new(user: admin)
        .call(principal: new_root, project_id: project.id, role_ids: [new_role.id])

      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: new_root.id)

      # Both mid and leaf should now have new_role, not old_role
      expect(mid_user.memberships.find_by(project:).roles).to contain_exactly(new_role)
      expect(leaf_user.memberships.find_by(project:).roles).to contain_exactly(new_role)
    end
  end

  # ---------------------------------------------------------------------------
  # Overlapping memberships at different hierarchy levels
  # ---------------------------------------------------------------------------

  describe "overlapping memberships at different levels" do
    it "keeps the mid group's own role when the parent link is broken, removing only the inherited root role" do
      root_role  = create(:project_role)
      mid_role   = create(:project_role)
      root_group = create(:group)
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      # Root group gets root_role, mid group gets its own mid_role
      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [root_role.id])
      Members::CreateService
        .new(user: admin)
        .call(principal: mid_group, project_id: project.id, role_ids: [mid_role.id])

      # Before breaking: mid_user has both roles, leaf_user has both roles
      expect(mid_user.memberships.find_by(project:).roles).to contain_exactly(root_role, mid_role)
      expect(leaf_user.memberships.find_by(project:).roles).to contain_exactly(root_role, mid_role)

      # Break the parent link
      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: nil)

      # After breaking: only mid_role remains — root_role was inherited and should be cleaned up
      expect(mid_user.memberships.find_by(project:).roles).to contain_exactly(mid_role)
      expect(leaf_user.memberships.find_by(project:).roles).to contain_exactly(mid_role)
    end
  end

  # ---------------------------------------------------------------------------
  # Deep hierarchy (more than 3 levels)
  # ---------------------------------------------------------------------------

  describe "deep hierarchy" do
    it "propagates memberships through a 5-level hierarchy" do
      users  = create_list(:user, 5)
      groups = users.each_with_object([]) do |u, acc|
        acc << create(:group, members: [u], parent: acc.last)
      end

      Members::CreateService
        .new(user: admin)
        .call(principal: groups[0], project_id: project.id, role_ids: [role.id])

      # Every user in the hierarchy should have the role
      users.each_with_index do |user, i|
        expect(user.memberships.find_by(project:)&.roles)
          .to contain_exactly(role),
              "expected user in group[#{i}] to have the role"
      end
    end

    it "cleans up memberships through a 5-level hierarchy when the parent link at level 2 is broken" do
      users  = create_list(:user, 5)
      groups = users.each_with_object([]) do |u, acc|
        acc << create(:group, members: [u], parent: acc.last)
      end

      Members::CreateService
        .new(user: admin)
        .call(principal: groups[0], project_id: project.id, role_ids: [role.id])

      # Break the link between groups[1] and groups[0]
      Groups::UpdateService
        .new(user: admin, model: groups[1])
        .call(parent_id: nil)

      # groups[0] user keeps the membership
      expect(users[0].memberships.find_by(project:)&.roles).to contain_exactly(role)

      # groups[1..4] users lose the inherited membership
      (1..4).each do |i|
        expect(users[i].memberships.find_by(project:))
          .to be_nil,
              "expected user in group[#{i}] to have no membership after breaking the link"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Diamond-shaped membership — user in both root and leaf
  # ---------------------------------------------------------------------------

  describe "diamond-shaped membership" do
    it "retains membership via root_group when the user is also in leaf_group and the parent link is broken" do
      shared_user = create(:user)
      root_group = create(:group, members: [shared_user])
      mid_group  = create(:group, parent: root_group)
      create(:group, members: [shared_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      # Break the hierarchy — leaf_group is no longer under root_group
      Groups::UpdateService
        .new(user: admin, model: mid_group)
        .call(parent_id: nil)

      # shared_user is still a direct member of root_group, so the membership survives
      expect(shared_user.memberships.find_by(project:)&.roles).to contain_exactly(role)
    end
  end

  # ---------------------------------------------------------------------------
  # Members::DeleteService — deleting a group membership cascades to descendants
  # ---------------------------------------------------------------------------

  describe "Members::DeleteService" do
    it "removes all inherited member_roles from descendant users when the root group's membership is deleted" do
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [role.id])

      group_member = Member.find_by!(principal: root_group, project:)

      Members::DeleteService
        .new(user: admin, model: group_member)
        .call

      expect(root_user.memberships.find_by(project:)).to be_nil
      expect(mid_user.memberships.find_by(project:)).to be_nil
      expect(leaf_user.memberships.find_by(project:)).to be_nil
    end

    it "keeps memberships from other groups when only one ancestor's membership is deleted" do
      root_role  = create(:project_role)
      mid_role   = create(:project_role)
      root_group = create(:group)
      mid_group  = create(:group, members: [mid_user], parent: root_group)
      create(:group, members: [leaf_user], parent: mid_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [root_role.id])
      Members::CreateService
        .new(user: admin)
        .call(principal: mid_group, project_id: project.id, role_ids: [mid_role.id])

      # Delete only the root group's membership
      root_member = Member.find_by!(principal: root_group, project:)
      Members::DeleteService
        .new(user: admin, model: root_member)
        .call

      # mid_role (from mid_group's own membership) should survive
      expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(mid_role)
      expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(mid_role)
    end
  end

  # ---------------------------------------------------------------------------
  # Adding a user to a group with memberships from multiple ancestors
  # ---------------------------------------------------------------------------

  describe "adding a user to a group with multiple ancestor memberships" do
    it "gives the new user roles inherited from both the group's own membership and its ancestor's membership" do
      root_role  = create(:project_role)
      mid_role   = create(:project_role)
      new_user   = create(:user)
      root_group = create(:group, members: [root_user])
      mid_group  = create(:group, parent: root_group)

      Members::CreateService
        .new(user: admin)
        .call(principal: root_group, project_id: project.id, role_ids: [root_role.id])
      Members::CreateService
        .new(user: admin)
        .call(principal: mid_group, project_id: project.id, role_ids: [mid_role.id])

      Groups::AddUsersService
        .new(mid_group, current_user: admin)
        .call(ids: [new_user.id], message: nil)

      # new_user should have both: mid_role from mid_group, root_role inherited from root_group
      expect(new_user.memberships.find_by(project:)&.roles).to contain_exactly(root_role, mid_role)
    end
  end

  # ---------------------------------------------------------------------------
  # Child group membership propagation — descendant groups themselves get
  # inherited Member records, not just the users within them
  # ---------------------------------------------------------------------------

  describe "child group membership propagation" do
    describe "Members::CreateService" do
      it "creates inherited memberships for descendant groups when a parent group is added to a project" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        mid_member = Member.find_by(principal: mid_group, project:)
        leaf_member = Member.find_by(principal: leaf_group, project:)

        expect(mid_member).to be_present
        expect(mid_member.roles).to contain_exactly(role)
        expect(mid_member.member_roles.all? { |mr| mr.inherited_from.present? }).to be(true)

        expect(leaf_member).to be_present
        expect(leaf_member.roles).to contain_exactly(role)
        expect(leaf_member.member_roles.all? { |mr| mr.inherited_from.present? }).to be(true)
      end

      it "does not create inherited memberships for ancestor groups" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: mid_group, project_id: project.id, role_ids: [role.id])

        expect(Member.find_by(principal: root_group, project:)).to be_nil
      end
    end

    describe "Members::UpdateService" do
      it "updates inherited roles on descendant group members when the parent group's roles change" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        second_role = create(:project_role)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        group_member = Member.find_by!(principal: root_group, project:)

        Members::UpdateService
          .new(user: admin, model: group_member)
          .call(role_ids: [role.id, second_role.id])

        expect(Member.find_by(principal: mid_group, project:).roles).to contain_exactly(role, second_role)
        expect(Member.find_by(principal: leaf_group, project:).roles).to contain_exactly(role, second_role)
      end
    end

    describe "Members::DeleteService" do
      it "removes inherited memberships from descendant groups when the parent group's membership is deleted" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        group_member = Member.find_by!(principal: root_group, project:)

        Members::DeleteService
          .new(user: admin, model: group_member)
          .call

        expect(Member.find_by(principal: mid_group, project:)).to be_nil
        expect(Member.find_by(principal: leaf_group, project:)).to be_nil
      end
    end

    describe "parent change" do
      it "propagates ancestor memberships to child groups when a parent is assigned" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user])
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        Groups::UpdateService
          .new(user: admin, model: mid_group)
          .call(parent_id: root_group.id)

        expect(Member.find_by(principal: mid_group, project:)&.roles).to contain_exactly(role)
        expect(Member.find_by(principal: leaf_group, project:)&.roles).to contain_exactly(role)
      end

      it "cleans up inherited child group memberships when the parent link is broken" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        # Verify child groups have memberships before breaking the link
        expect(Member.find_by(principal: mid_group, project:)).to be_present
        expect(Member.find_by(principal: leaf_group, project:)).to be_present

        Groups::UpdateService
          .new(user: admin, model: mid_group)
          .call(parent_id: nil)

        expect(Member.find_by(principal: mid_group, project:)).to be_nil
        expect(Member.find_by(principal: leaf_group, project:)).to be_nil
      end
    end

    describe "Members::DeleteService with pre-existing child group membership" do
      it "retains the child group's own membership when the parent group's membership is deleted" do
        mid_role   = create(:project_role)
        root_role  = create(:project_role)
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        # mid_group gets its own direct membership first
        Members::CreateService
          .new(user: admin)
          .call(principal: mid_group, project_id: project.id, role_ids: [mid_role.id])

        # Then root_group is added — this propagates root_role to mid_group, leaf_group, and all users
        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [root_role.id])

        # mid_group now has both its direct mid_role and inherited root_role
        expect(Member.find_by(principal: mid_group, project:).roles).to contain_exactly(mid_role, root_role)
        expect(Member.find_by(principal: leaf_group, project:)&.roles).to contain_exactly(mid_role, root_role)

        # Delete root_group's membership
        root_member = Member.find_by!(principal: root_group, project:)
        Members::DeleteService
          .new(user: admin, model: root_member)
          .call

        # mid_group keeps its own direct membership with mid_role
        expect(Member.find_by(principal: mid_group, project:)&.roles).to contain_exactly(mid_role)
        # leaf_group keeps the inherited mid_role from mid_group
        expect(Member.find_by(principal: leaf_group, project:)&.roles).to contain_exactly(mid_role)
        # Users also retain mid_role
        expect(mid_user.memberships.find_by(project:)&.roles).to contain_exactly(mid_role)
        expect(leaf_user.memberships.find_by(project:)&.roles).to contain_exactly(mid_role)
      end
    end

    describe "user removal from group" do
      it "does not affect child group memberships when a user is removed from a group" do
        root_group = create(:group, members: [root_user])
        mid_group  = create(:group, members: [mid_user], parent: root_group)
        leaf_group = create(:group, members: [leaf_user], parent: mid_group)

        Members::CreateService
          .new(user: admin)
          .call(principal: root_group, project_id: project.id, role_ids: [role.id])

        # Remove leaf_user from leaf_group
        Groups::UpdateService
          .new(user: admin, model: leaf_group)
          .call(remove_user_ids: [leaf_user.id])

        # Child group memberships should remain intact
        expect(Member.find_by(principal: mid_group, project:)&.roles).to contain_exactly(role)
        expect(Member.find_by(principal: leaf_group, project:)&.roles).to contain_exactly(role)
      end
    end
  end
end
