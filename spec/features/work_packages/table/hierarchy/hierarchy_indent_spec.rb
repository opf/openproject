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

RSpec.describe "Work Package table hierarchy and sorting", :js do
  shared_let(:project) { create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }
  let(:sort_by) { Components::WorkPackages::SortBy.new }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }

  shared_let(:wp_root) do
    create(:work_package,
           project:,
           subject: "Parent")
  end

  shared_let(:wp_child1) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "WP child 1")
  end

  shared_let(:wp_child2) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "WP child 2")
  end

  shared_let(:wp_child3) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: "WP child 3")
  end

  shared_current_user { create(:admin) }

  it "can indent hierarchies" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect indent-able for all except wp_root wp_child
    hierarchy.expect_indent(wp_root, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: true)
    hierarchy.expect_indent(wp_child2, indent: true, outdent: true)
    hierarchy.expect_indent(wp_child3, indent: true, outdent: true)

    # Located up front, so that the check right after the confirmation runs at once
    treegrid = wp_table.treegrid

    # Indent last child
    hierarchy.indent! wp_child3

    # The confirmation only appears once the table shows the new hierarchy
    wp_table.expect_toast message: "Successful update."
    expect(treegrid).to have_selector(:row, "WP child 3", aria: { level: 3 }, wait: 0)
    # A menu opened with the pointer returns focus to the cell it was opened on
    wp_table.expect_focus_on_cell(wp_child3, :subject)
    wp_table.dismiss_toaster!
    wp_table.expect_no_toaster message: "Successful update."

    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    # Remove first child
    hierarchy.outdent! wp_child1

    wp_table.expect_toast message: "Successful update."
    expect(treegrid).to have_selector(:row, "WP child 1", aria: { level: 1 }, wait: 0)
    wp_table.expect_focus_on_cell(wp_child1, :subject)
    wp_table.dismiss_toaster!

    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    wp_table.visit!
    expect(wp_table.treegrid).to have_selector(:row, "Parent", aria: { level: 1 })
    expect(wp_table.treegrid).to have_selector(:row, "WP child 1", aria: { level: 1 })
    expect(wp_table.treegrid).to have_selector(:row, "WP child 2", aria: { level: 2 })
    expect(wp_table.treegrid).to have_selector(:row, "WP child 3", aria: { level: 3 })
  end

  it "returns focus to the row after indenting from the keyboard" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)

    wp_table.focus_row_by_keyboard(wp_child3)
    wp_table.press_keys(%i[shift alt f10])
    context_menu.expect_open
    context_menu.choose("Indent hierarchy")

    wp_table.expect_toast message: "Successful update."
    wp_table.expect_focus_on_row(wp_child3)
    expect(wp_table.treegrid).to have_selector(:row, "WP child 3", aria: { level: 3 })
  end

  it "can edit a work package, then indent, and then edit again (Regression #30994)" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    subject = wp_table.edit_field(wp_child3, :subject)
    subject.update "First edit"
    wait_for_network_idle
    wp_table.expect_and_dismiss_toaster message: "Successful update."

    # Indent last child
    hierarchy.indent! wp_child3
    wait_for_network_idle
    wp_table.expect_and_dismiss_toaster message: "Successful update."

    # Expect changed
    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    subject = wp_table.edit_field(wp_child3, :subject)
    subject.update "Second edit"
    wait_for_network_idle
    wp_table.expect_and_dismiss_toaster message: "Successful update."

    wp_table.visit!
    expect(wp_table.treegrid).to have_selector(:row, "Second edit", aria: { level: 3 })
  end

  it "reports a conflict and keeps focus on the row when the work package was changed elsewhere" do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)

    WorkPackage.find(wp_child3.id).update!(subject: "Changed elsewhere")

    wp_table.focus_row_by_keyboard(wp_child3)
    wp_table.press_keys(%i[shift alt f10])
    context_menu.expect_open
    context_menu.choose("Indent hierarchy")

    wp_table.expect_flash(type: :error, message: "Could not save your changes because of conflicting modifications.")
    wp_table.expect_no_toaster message: "Successful update."
    wp_table.expect_focus_on_row(wp_child3)

    wp_table.visit!
    expect(wp_table.treegrid).to have_selector(:row, "Changed elsewhere", aria: { level: 2 })
  end
end
