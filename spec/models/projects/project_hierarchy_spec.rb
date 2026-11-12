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

RSpec.describe Project, "hierarchy" do
  shared_let(:current_user) { create(:user) }
  shared_let(:role) { create(:project_role) }

  before do
    login_as current_user
  end

  describe ".nearest_visible_descendants" do
    shared_let(:root) { create(:project, name: "Root") }
    shared_let(:child) { create(:project, name: "Child", parent: root) }
    shared_let(:grandchild) { create(:project, name: "Grandchild", parent: child) }
    shared_let(:archived_child) { create(:project, name: "Archived child", parent: root, active: false) }
    shared_let(:other_root) { create(:project, name: "Other root") }
    shared_let(:archived_root) { create(:project, name: "Archived root", active: false) }

    before do
      [root, child, grandchild, archived_child, other_root, archived_root].each do |project|
        create(:member, principal: current_user, project:, roles: [role])
      end
    end

    context "without a boundary" do
      it "returns visible, active root-level projects" do
        expect(described_class.nearest_visible_descendants).to contain_exactly(root, other_root)
      end

      it "does not return a project nested under a visible parent" do
        expect(described_class.nearest_visible_descendants).not_to include(child)
      end

      it "does not return an archived root project" do
        expect(described_class.nearest_visible_descendants).not_to include(archived_root)
      end

      it "respects the limit and orders by lft" do
        lft_first = [root, other_root].min_by(&:lft)

        expect(described_class.nearest_visible_descendants(limit: 1)).to contain_exactly(lft_first)
      end

      context "when a visible project's real parent is invisible" do
        shared_let(:hidden_root) { create(:private_project, name: "Hidden root") }
        shared_let(:promoted) { create(:project, name: "Promoted", parent: hidden_root) }

        before do
          create(:member, principal: current_user, project: promoted, roles: [role])
        end

        it "promotes the project to the top level instead of hiding it" do
          expect(described_class.nearest_visible_descendants).to include(promoted)
          expect(described_class.nearest_visible_descendants).not_to include(hidden_root)
        end
      end
    end

    context "with a boundary" do
      it "returns only the boundary's direct visible, active children" do
        expect(described_class.nearest_visible_descendants(root)).to contain_exactly(child)
      end

      it "does not return grandchildren behind a visible child" do
        expect(described_class.nearest_visible_descendants(root)).not_to include(grandchild)
      end

      it "does not return an archived child" do
        expect(described_class.nearest_visible_descendants(root)).not_to include(archived_child)
      end

      it "does not return a project from a different root" do
        expect(described_class.nearest_visible_descendants(root)).not_to include(other_root)
      end

      context "when the direct child is invisible but the grandchild is visible" do
        shared_let(:hidden_child) { create(:private_project, name: "Hidden child", parent: root) }
        shared_let(:visible_grandchild) { create(:project, name: "Visible grandchild", parent: hidden_child) }

        before do
          create(:member, principal: current_user, project: visible_grandchild, roles: [role])
        end

        it "skips the invisible child and surfaces the nearest visible descendant" do
          result = described_class.nearest_visible_descendants(root)
          expect(result).to include(visible_grandchild)
          expect(result).not_to include(hidden_child)
        end
      end
    end
  end

  describe ".having_visible_descendants" do
    shared_let(:parent) { create(:project, name: "Parent") }
    shared_let(:child) { create(:project, name: "Child", parent:) }
    shared_let(:leaf) { create(:project, name: "Leaf") }

    before do
      [parent, child, leaf].each do |project|
        create(:member, principal: current_user, project:, roles: [role])
      end
    end

    it "includes a project that has a visible, active descendant" do
      expect(described_class.having_visible_descendants([parent, leaf])).to contain_exactly(parent)
    end

    it "excludes a project without descendants" do
      expect(described_class.having_visible_descendants([parent, leaf])).not_to include(leaf)
    end

    it "excludes a candidate that is itself a descendant with no descendants of its own" do
      expect(described_class.having_visible_descendants([parent, child, leaf])).to contain_exactly(parent)
    end

    it "accepts a single project instead of an array" do
      expect(described_class.having_visible_descendants(parent)).to contain_exactly(parent)
    end

    it "returns none for an empty array" do
      expect(described_class.having_visible_descendants([])).to be_empty
    end

    context "when the only descendant is invisible" do
      shared_let(:lonely_parent) { create(:project, name: "Lonely parent") }
      shared_let(:hidden_child) { create(:private_project, name: "Hidden child", parent: lonely_parent) }

      before do
        create(:member, principal: current_user, project: lonely_parent, roles: [role])
      end

      it "excludes that project" do
        expect(described_class.having_visible_descendants([lonely_parent])).not_to include(lonely_parent)
      end
    end

    context "when the only descendant is archived" do
      shared_let(:parent_of_archived) { create(:project, name: "Parent of archived") }
      shared_let(:archived_child) { create(:project, name: "Archived child", parent: parent_of_archived, active: false) }

      before do
        create(:member, principal: current_user, project: parent_of_archived, roles: [role])
      end

      it "excludes that project" do
        expect(described_class.having_visible_descendants([parent_of_archived])).not_to include(parent_of_archived)
      end
    end
  end
end
