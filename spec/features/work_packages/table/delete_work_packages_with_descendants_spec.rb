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

RSpec.describe "Delete work packages that have descendants", :js do
  let(:user) { create(:admin) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }

  before do
    login_as(user)
  end

  describe "deleting a single work package" do
    let(:project) { create(:project) }
    let!(:parent) { create(:work_package, project:, subject: "Parent wp") }
    let!(:child) { create(:work_package, project:, parent:, subject: "Child wp") }

    let(:wp_table) { Pages::WorkPackagesTable.new(project.identifier) }
    let(:destroy_modal) { Components::WorkPackages::DestroyModal.new }

    before do
      wp_table.visit!
      wp_table.expect_work_package_listed(parent, child)
      context_menu.open_for(parent)
      context_menu.choose("Delete")
      destroy_modal.expect_descendants_choice
    end

    it "cascades to the descendants when the user chooses to" do
      destroy_modal.confirm_descendants_deletion

      loading_indicator_saveguard
      wp_table.expect_no_work_package_listed
      expect(WorkPackage).not_to exist(parent.id)
      expect(WorkPackage).not_to exist(child.id)
    end

    it "detaches the descendants when the user keeps them" do
      destroy_modal.confirm_roots_only_deletion

      loading_indicator_saveguard
      wp_table.ensure_work_package_not_listed!(parent)
      wp_table.expect_work_package_listed(child)
      expect(WorkPackage).not_to exist(parent.id)
      expect(child.reload.parent_id).to be_nil
    end
  end

  describe "bulk deleting across projects" do
    let!(:project_a) { create(:project, name: "Project Alpha") }
    let!(:project_b) { create(:project, name: "Project Beta") }
    let!(:parent_a) { create(:work_package, project: project_a, subject: "Parent Alpha") }
    let!(:child_a) { create(:work_package, project: project_a, parent: parent_a, subject: "Child Alpha") }
    let!(:parent_b) { create(:work_package, project: project_b, subject: "Parent Beta") }
    let!(:child_b) { create(:work_package, project: project_b, parent: parent_b, subject: "Child Beta") }

    let(:query) do
      create(:query, project: nil, user:, show_hierarchies: false).tap do |q|
        q.add_filter("id", "=", [parent_a.id.to_s, parent_b.id.to_s])
        q.save(validate: false)
      end
    end

    let(:wp_table) { Pages::WorkPackagesTable.new }
    let(:destroy_modal) { Components::WorkPackages::DestroyModal.new(bulk_mode: true) }

    it "warns that it spans projects and cascades the whole hierarchy" do
      wp_table.visit_query(query)
      wp_table.expect_work_package_listed(parent_a, parent_b)

      find("body").send_keys [:control, "a"]
      context_menu.open_for(parent_a)
      context_menu.choose("Bulk delete")

      destroy_modal.expect_descendants_choice
      destroy_modal.expect_cross_project_warning(project_a, project_b)
      destroy_modal.confirm_descendants_deletion

      loading_indicator_saveguard
      wp_table.expect_no_work_package_listed
      expect(WorkPackage.count).to eq(0)
    end
  end
end
