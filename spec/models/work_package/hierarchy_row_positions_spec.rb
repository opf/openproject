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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackage::HierarchyRowPositions, with_settings: { cross_project_work_package_relations: true } do
  shared_let(:project) { create(:project) }
  shared_let(:hidden_project) { create(:project) }
  shared_let(:user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }

  subject(:positions) { described_class.new(ranked(*results), user) }

  def ranked(*work_packages)
    ids = work_packages.map(&:id)
    WorkPackage
      .where(id: ids)
      .order(Arel.sql("array_position(ARRAY[#{ids.map(&:to_i).join(',')}]::integer[], work_packages.id)"))
  end

  def entry(position, parent = nil)
    { position:, parent: parent&.id&.to_s }
  end

  def all_entries
    positions.entries_for(results.map(&:id))
  end

  context "with flat roots" do
    let(:first) { create(:work_package, project:) }
    let(:second) { create(:work_package, project:) }
    let(:results) { [first, second] }

    it "numbers them in query order" do
      expect(positions.count).to eq(2)
      expect(all_entries).to eq(first.id.to_s => entry(1), second.id.to_s => entry(2))
    end
  end

  context "with a child ranked before its parent" do
    let(:parent) { create(:work_package, project:) }
    let(:child) { create(:work_package, project:, parent:) }
    let(:other) { create(:work_package, project:) }
    let(:results) { [child, other, parent] }

    it "places the parent subtree at the child's rank" do
      expect(positions.count).to eq(3)
      expect(all_entries).to eq(parent.id.to_s => entry(1),
                                child.id.to_s => entry(2, parent),
                                other.id.to_s => entry(3))
    end
  end

  context "with a parent that does not match" do
    let(:parent) { create(:work_package, project:) }
    let(:child) { create(:work_package, project:, parent:) }
    let(:results) { [child] }

    it "counts the contextual ancestor" do
      expect(positions.count).to eq(2)
      expect(all_entries).to eq(parent.id.to_s => entry(1), child.id.to_s => entry(2, parent))
    end
  end

  context "with a nested hierarchy" do
    let(:root) { create(:work_package, project:) }
    let(:middle) { create(:work_package, project:, parent: root) }
    let(:grandchild) { create(:work_package, project:, parent: middle) }
    let(:second_root) { create(:work_package, project:) }
    let(:results) { [grandchild, second_root] }

    it "inserts every contextual ancestor depth first" do
      expect(positions.count).to eq(4)
      expect(all_entries).to eq(root.id.to_s => entry(1),
                                middle.id.to_s => entry(2, root),
                                grandchild.id.to_s => entry(3, middle),
                                second_root.id.to_s => entry(4))
    end
  end

  context "with results sharing a contextual ancestor" do
    let(:parent) { create(:work_package, project:) }
    let(:first_child) { create(:work_package, project:, parent:) }
    let(:second_child) { create(:work_package, project:, parent:) }
    let(:other) { create(:work_package, project:) }
    let(:results) { [first_child, other, second_child] }

    it "counts the ancestor once and keeps siblings in query order" do
      expect(positions.count).to eq(4)
      expect(all_entries).to eq(parent.id.to_s => entry(1),
                                first_child.id.to_s => entry(2, parent),
                                second_child.id.to_s => entry(3, parent),
                                other.id.to_s => entry(4))
    end
  end

  context "with an invisible middle ancestor" do
    let(:grandparent) { create(:work_package, project:) }
    let(:hidden_parent) { create(:work_package, project: hidden_project, parent: grandparent) }
    let(:leaf) { create(:work_package, project:, parent: hidden_parent) }
    let(:results) { [leaf] }

    it "parents the row to its nearest visible ancestor" do
      expect(positions.count).to eq(2)
      expect(all_entries).to eq(grandparent.id.to_s => entry(1), leaf.id.to_s => entry(2, grandparent))
    end
  end

  context "without results" do
    let(:results) { [] }

    it "has no rows" do
      expect(positions.count).to eq(0)
      expect(positions.entries_for([])).to eq({})
    end
  end

  describe "#entries_for" do
    let(:parent) { create(:work_package, project:) }
    let(:child) { create(:work_package, project:, parent:) }
    let(:other) { create(:work_package, project:) }
    let(:results) { [child, other] }

    it "returns the given rows and their visible ancestors only" do
      expect(positions.entries_for([child.id])).to eq(parent.id.to_s => entry(1), child.id.to_s => entry(2, parent))
    end

    it "returns nothing when a row is not among the numbered results" do
      expect(positions.entries_for([child.id, parent.id + 1000])).to be_nil
    end
  end
end
