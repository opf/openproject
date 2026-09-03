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

RSpec.describe WorkPackages::Shared::DeletionPlanning do
  # A bare host, so the walk can be checked without a service or a dialog around it.
  let(:host_class) do
    Class.new do
      include WorkPackages::Shared::DeletionPlanning

      attr_reader :deletion_roots, :deletion_user

      def initialize(roots, user)
        @deletion_roots = Array(roots)
        @deletion_user = user
      end

      def include_descendants? = true
    end
  end

  let(:home_permissions) { %i[view_work_packages delete_work_packages] }
  let(:user) do
    create(:user,
           member_with_permissions: {
             home_project => home_permissions,
             view_only_project => %i[view_work_packages]
           })
  end

  shared_let(:home_project) { create(:project) }
  shared_let(:view_only_project) { create(:project) }
  shared_let(:invisible_project) { create(:project) }

  subject(:plan) { host_class.new(roots, user) }

  describe "a chain of deletable descendants" do
    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: home_project, parent: root) }
    let!(:grandchild) { create(:work_package, project: home_project, parent: child) }
    let(:roots) { root }

    it "deletes all of them, nearest first" do
      expect(plan.deleted_descendants).to eq([child, grandchild])
      expect(plan.unlinked_descendants).to be_empty
    end

    it "reports them under the root they hang from" do
      expect(plan.deleted_descendants_under(root)).to eq([child, grandchild])
    end
  end

  describe "a descendant the user may not delete" do
    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: view_only_project, parent: root) }
    let(:roots) { root }

    it "cuts it loose rather than deleting it" do
      expect(plan.deleted_descendants).to be_empty
      expect(plan.unlinked_descendants).to eq([child])
    end

    it "counts it as visible" do
      expect(plan.visible_unlinked_descendants).to eq([child])
      expect(plan.hidden_unlinked_count).to eq(0)
    end

    # Filtering flat instead of walking would delete the grandchild while its
    # parent survives.
    context "with a deletable subtree below it" do
      let!(:grandchild) { create(:work_package, project: home_project, parent: child) }

      it "leaves the subtree out of both lists" do
        expect(plan.deleted_descendants).to be_empty
        expect(plan.unlinked_descendants).to eq([child])
      end
    end
  end

  describe "an invisible descendant" do
    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: invisible_project, parent: root) }
    let(:roots) { root }

    it "is cut loose but not counted as visible" do
      expect(plan.unlinked_descendants).to eq([child])
      expect(plan.visible_unlinked_descendants).to be_empty
      expect(plan.hidden_unlinked_count).to eq(1)
    end
  end

  # Seeing and deleting are separate permissions, so a role can carry the second
  # without the first. Either one missing means the descendant is cut loose.
  describe "a descendant the user may delete but not see" do
    shared_let(:delete_only_project) { create(:project) }
    let(:user) do
      create(:user,
             member_with_permissions: {
               home_project => home_permissions,
               delete_only_project => %i[delete_work_packages]
             })
    end

    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: delete_only_project, parent: root) }
    let(:roots) { root }

    it "is cut loose rather than deleted" do
      expect(plan.deleted_descendants).to be_empty
      expect(plan.unlinked_descendants).to eq([child])
    end
  end

  describe "several roots where one is a descendant of another" do
    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: home_project, parent: root) }
    let!(:grandchild) { create(:work_package, project: home_project, parent: child) }
    let(:roots) { [root, child] }

    it "reports the grandchild once, under the nearest selected root" do
      expect(plan.deleted_descendants).to eq([grandchild])
      expect(plan.deleted_descendants_under(root)).to be_empty
      expect(plan.deleted_descendants_under(child)).to eq([grandchild])
    end
  end

  describe "with an overridden deletability check" do
    let(:host_class) do
      Class.new do
        include WorkPackages::Shared::DeletionPlanning

        attr_reader :deletion_roots, :deletion_user

        def initialize(roots, user)
          @deletion_roots = Array(roots)
          @deletion_user = user
        end

        def include_descendants? = true
        def deletable?(_descendant) = false
      end
    end

    let!(:root) { create(:work_package, project: home_project) }
    let!(:child) { create(:work_package, project: home_project, parent: root) }
    let(:roots) { root }

    it "uses the override instead of the delete permission" do
      expect(plan.deleted_descendants).to be_empty
      expect(plan.unlinked_descendants).to eq([child])
    end
  end
end
