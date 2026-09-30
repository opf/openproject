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

require "rails_helper"

RSpec.describe WorkPackages::ScheduleDependency do
  create_shared_association_defaults_for_work_package_factory

  describe "#descendants" do
    shared_let(:work_package) { create(:work_package) }
    let(:schedule_dependency) { described_class.new(work_package) }

    context "with a simple hierarchy" do
      let!(:child1) { create(:work_package, parent: work_package) }
      let!(:child2) { create(:work_package, parent: work_package) }

      it "returns all direct children" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child1, child2)
      end
    end

    context "with multiple levels" do
      let!(:child) { create(:work_package, parent: work_package) }
      let!(:grandchild) { create(:work_package, parent: child) }
      let!(:great_grandchild) { create(:work_package, parent: grandchild) }

      it "returns all descendants at all levels" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child, grandchild, great_grandchild)
      end
    end

    context "with multiple branches" do
      let!(:child1) { create(:work_package, parent: work_package) }
      let!(:child2) { create(:work_package, parent: work_package) }
      let!(:grandchild1) { create(:work_package, parent: child1) }
      let!(:grandchild2) { create(:work_package, parent: child2) }

      it "returns all descendants from all branches" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(
          child1, child2, grandchild1, grandchild2
        )
      end
    end

    context "with caching" do
      let!(:child) { create(:work_package, parent: work_package) }

      it "caches the result" do
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)

        # Create a new child after the first call
        create(:work_package, parent: work_package)

        # Should still return the cached result
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)
      end
    end

    context "with a cycle in the hierarchy" do
      let!(:child) { create(:work_package, parent: work_package) }

      before do
        # Create a cycle by making the work package a child of its child
        work_package.update_column(:parent_id, child.id)
      end

      it "handles the cycle gracefully" do
        expect { schedule_dependency.descendants(work_package) }.not_to raise_error
        expect(schedule_dependency.descendants(work_package)).to contain_exactly(child)
      end
    end

    context "with no children" do
      it "returns an empty array" do
        expect(schedule_dependency.descendants(work_package)).to be_empty
      end
    end
  end

  describe "#automatically_scheduled_ancestors" do
    shared_let(:work_package) { create(:work_package, subject: "work_package") }
    let(:schedule_dependency) { described_class.new(work_package) }

    context "with no parent" do
      it "returns an empty array" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to be_empty
      end
    end

    context "with a single automatically scheduled parent" do
      let_work_packages(<<~TABLE)
        hierarchy | scheduling mode
        parent    | automatic
      TABLE

      before do
        work_package.update(parent:)
      end

      it "returns the parent" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to contain_exactly(parent)
      end
    end

    context "with a manually scheduled parent" do
      let_work_packages(<<~TABLE)
        hierarchy | scheduling mode
        parent    | manual
      TABLE

      before do
        work_package.update(parent:)
      end

      it "returns an empty array" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to be_empty
      end
    end

    context "with multiple levels of automatically scheduled ancestors" do
      let_work_packages(<<~TABLE)
        hierarchy   | scheduling mode
        grandparent | automatic
          parent    | automatic
      TABLE

      before do
        work_package.update(parent:)
      end

      it "returns all automatically scheduled ancestors" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to contain_exactly(parent, grandparent)
      end
    end

    context "with mixed scheduling modes in the hierarchy" do
      let_work_packages(<<~TABLE)
        hierarchy   | scheduling mode
        grandparent | automatic
          parent    | manual
      TABLE

      before do
        work_package.update(parent:)
      end

      it "returns only automatically scheduled ancestors" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to be_empty
      end
    end

    context "with a cycle in the hierarchy" do
      let_work_packages(<<~TABLE)
        hierarchy    | scheduling mode
        child        | automatic
          grandchild | manual
      TABLE

      before do
        child.update(parent: work_package)
        work_package.update(schedule_manually: false)

        # Create the cycle: set the parent with a current child, but do not
        # save, like when set by an update during a set attributes service call
        work_package.parent = child
      end

      it "handles the cycle gracefully and does not cause an infinite loop" do
        expect { schedule_dependency.automatically_scheduled_ancestors(work_package) }.not_to raise_error
        # Should return the parent but not get stuck in an infinite loop
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to contain_exactly(child)
      end
    end

    context "with a complex hierarchy" do
      let_work_packages(<<~TABLE)
        hierarchy         | scheduling mode
        great_grandparent | automatic
          grandparent     | manual
            parent        | automatic
      TABLE

      before do
        work_package.update(parent:)
      end

      it "returns only automatically scheduled ancestors" do
        expect(schedule_dependency.automatically_scheduled_ancestors(work_package)).to contain_exactly(parent)
      end
    end
  end
end
