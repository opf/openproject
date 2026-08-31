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

RSpec.describe Queries::Members::Filters::GroupHierarchyFilter do
  include_context "filter tests"

  let(:project) { create(:project) }
  let(:admin) { create(:admin) }
  let(:role) { create(:project_role) }

  let(:root_user) { create(:user) }
  let(:mid_user) { create(:user) }
  let(:leaf_user) { create(:user) }
  let(:unrelated_user) { create(:user) }

  let!(:root_group) { create(:group, members: [root_user]) }
  let!(:mid_group)  { create(:group, members: [mid_user], parent: root_group) }
  let!(:leaf_group) { create(:group, members: [leaf_user], parent: mid_group) }
  let!(:other_group) { create(:group, members: [unrelated_user]) }

  before do
    allow(Notifications::GroupMemberAlteredJob).to receive(:perform_later)

    Members::CreateService
      .new(user: admin)
      .call(principal: root_group, project_id: project.id, role_ids: [role.id])
  end

  it "has key :group_hierarchy" do
    expect(described_class.key).to eq(:group_hierarchy)
  end

  describe "#allowed_values" do
    it "lists all group IDs" do
      expect(instance.allowed_values.map(&:first))
        .to include(root_group.id, mid_group.id, leaf_group.id, other_group.id)
    end
  end

  describe '#where with operator "="' do
    let(:operator) { "=" }
    let(:values) { [root_group.id.to_s] }

    it "returns members for users in the group and its descendants, plus the descendant groups" do
      members = Member.joins(:principal).where(project:).where(instance.where)

      principal_ids = members.pluck(:user_id)

      # Users from root, mid, and leaf groups
      expect(principal_ids).to include(root_user.id, mid_user.id, leaf_user.id)
      # Descendant groups themselves
      expect(principal_ids).to include(mid_group.id, leaf_group.id)
      # The root group itself (it's in the tree)
      expect(principal_ids).to include(root_group.id)
      # Unrelated user is excluded
      expect(principal_ids).not_to include(unrelated_user.id)
    end
  end

  describe '#where with operator "!"' do
    let(:operator) { "!" }
    let(:values) { [root_group.id.to_s] }

    it "excludes members for users in the group hierarchy and the descendant groups" do
      # Add unrelated_user as a member so there's something to match
      Members::CreateService
        .new(user: admin)
        .call(principal: other_group, project_id: project.id, role_ids: [role.id])

      members = Member.joins(:principal).where(project:).where(instance.where)
      principal_ids = members.pluck(:user_id)

      expect(principal_ids).to include(unrelated_user.id, other_group.id)
      expect(principal_ids).not_to include(root_user.id, mid_user.id, leaf_user.id)
      expect(principal_ids).not_to include(mid_group.id, leaf_group.id)
    end
  end
end
