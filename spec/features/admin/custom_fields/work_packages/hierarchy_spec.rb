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
require_relative "../shared_custom_field_expectations"

RSpec.describe "work package custom fields of type hierarchy", :js do
  shared_let(:admin) { create(:admin) }
  let(:custom_field_index_page) { Pages::CustomFields::Index.new }
  let(:new_custom_field_page) { Pages::CustomFields::New.new }
  let(:hierarchy_page) { Pages::CustomFields::Hierarchy.new }

  current_user { admin }

  it "lets you create, update and delete a custom field of type hierarchy", with_ee: [:custom_field_hierarchies] do
    # region CustomField creation
    custom_field_index_page.visit!

    custom_field_index_page.click_to_create_new_custom_field("Hierarchy")

    hierarchy_name = "Stormtrooper Organisation"
    fill_in "Name", with: hierarchy_name
    click_on "Save"

    expect(page).to have_text("Successful creation.")

    CustomField.find_by(name: hierarchy_name).tap do |custom_field|
      hierarchy_page.add_custom_field_state(custom_field)
    end
    hierarchy_page.expect_current_path

    # endregion

    # region Edit the details of the custom field

    expect(page).to have_test_selector("op-custom-fields--top-banner")
    expect(page).to have_css(".PageHeader-title", text: hierarchy_name)

    # Now, that was the wrong name, so I can change it to the correct one
    hierarchy_name = "Imperial Organisation"
    fill_in "Name", with: "", fill_options: { clear: :backspace }
    fill_in "Name", with: hierarchy_name
    click_on "Save"

    expect(page).to have_heading(hierarchy_name)

    # endregion

    # region Adding items to the hierarchy

    # Now we want to create our first hierarchy items
    hierarchy_page.switch_tab "Items"
    hierarchy_page.expect_current_path
    expect(page).to have_test_selector("op-custom-fields--hierarchy-items-blankslate")

    within("sub-header") { click_on "Item" }
    expect(page).not_to have_test_selector("op-custom-fields--hierarchy-items-blankslate")
    fill_in "Item label", with: "Stormtroopers"
    fill_in "Short name", with: "ST"
    click_on "Save"
    expect(page).not_to have_test_selector("op-custom-fields--hierarchy-items-blankslate")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 1)
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Stormtroopers")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "(ST)")

    # And the inline form should still be there
    expect(page).to have_test_selector("op-custom-fields--new-item-form")

    # Can I add the same item again?
    fill_in "Item label", with: "Stormtroopers"
    click_on "Save"
    within_test_selector("op-custom-fields--new-item-form") do
      expect(page).to have_css(".FormControl-inlineValidation", text: "Label must be unique within the same hierarchy level")
    end

    # Is the form cancelable?
    fill_in "Item label", with: "Dark Troopers"
    click_on "Cancel"
    expect(page).not_to have_test_selector("op-custom-fields--new-item-form")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 1)
    expect(page).not_to have_test_selector("op-custom-fields--hierarchy-item", text: "Dark Troopers")

    # endregion

    # region Deleting items from the hierarchy

    # What happens if I added a wrong item?
    click_on "Item"
    fill_in "Item label", with: "Phoenix Squad"
    click_on "Save"
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 2)
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Phoenix Squad")
    hierarchy_page.open_action_menu_for("Phoenix Squad")
    click_on "Delete"
    expect(page).to have_test_selector("op-custom-fields--delete-item-dialog")
    check "I understand that this deletion cannot be reversed", allow_label_click: true
    click_on "Delete permanently"
    expect(page).not_to have_test_selector("op-custom-fields--delete-item-dialog")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 1)
    expect(page).not_to have_test_selector("op-custom-fields--hierarchy-item", text: "Phoenix Squad")

    # Can I cancel the deletion?
    hierarchy_page.open_action_menu_for("Stormtroopers")
    click_on "Delete"
    expect(page).to have_test_selector("op-custom-fields--delete-item-dialog")
    click_on "Cancel"
    expect(page).not_to have_test_selector("op-custom-fields--delete-item-dialog")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Stormtroopers")

    # endregion

    # region Status check and cleanup

    # And is the blue banner gone, now that I have added some items?
    hierarchy_page.switch_tab "Details"
    expect(page).not_to have_test_selector("op-custom-fields--top-banner")

    # Finally, we delete the custom field ... I'm done with this ...
    custom_field_index_page.visit!
    expect(page).to have_row(hierarchy_name)
    within("tr", text: hierarchy_name) { accept_prompt { click_on "Delete" } }
    expect(page).to have_no_text(hierarchy_name)

    # endregion
  end

  it "lets you add sub-items through the context menu", with_ee: [:custom_field_hierarchies] do
    custom_field = create(:hierarchy_wp_custom_field, name: "Imperial Organization")
    root = custom_field.hierarchy_root

    root.children.create(label: "Stormtroopers", short: "ST")
    root.children.create(label: "Imperial Navy", short: "IN")

    login_as admin
    custom_field_index_page.visit!

    hierarchy_page.add_custom_field_state(custom_field)
    click_on custom_field.name

    hierarchy_page.switch_tab "Items"
    hierarchy_page.expect_current_path
    expect(page).not_to have_test_selector("op-custom-fields--hierarchy-items-blankslate")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 2)

    hierarchy_page.open_action_menu_for("Stormtroopers")
    click_on "Add sub-item"

    expect(page).to have_test_selector("op-custom-fields--new-item-form")
    fill_in "Item label", with: "Snowtroopers"
    fill_in "Short name", with: "SnT"
    click_on "Save"

    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 1)
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Snowtroopers")

    within('[data-test-selector="hierarchy-breadcrumbs"]') { click_on "Imperial Organization" }
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 2)
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Imperial Navy")
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Stormtroopers\n(ST)\n1 sub-item")
  end

  context "when navigating the hierarchy", with_ee: [:custom_field_hierarchies] do
    let(:service) { CustomFields::Hierarchy::HierarchicalItemService.new }
    let(:custom_field) { create(:wp_custom_field, name: "Hogwarts", field_format: "hierarchy", hierarchy_root: nil) }
    let!(:root) { service.generate_root(custom_field).value! }
    let(:contract_class) { CustomFields::Hierarchy::InsertListItemContract }
    let!(:ravenclaw) { service.insert_item(contract_class:, parent: root, label: "Ravenclaw").value! }
    let!(:slytherin) { service.insert_item(contract_class:, parent: root, label: "Slytherin").value! }
    let!(:hufflepuff) { service.insert_item(contract_class:, parent: root, label: "Hufflepuff").value! }
    let!(:gryffindor) { service.insert_item(contract_class:, parent: root, label: "Gryffindor").value! }
    let!(:luna) { service.insert_item(contract_class:, parent: ravenclaw, label: "Luna Lovegood").value! }
    let!(:harry) { service.insert_item(contract_class:, parent: gryffindor, label: "Harry Potter").value! }
    let!(:hermione) { service.insert_item(contract_class:, parent: gryffindor, label: "Hermione Granger").value! }
    let(:tree_view) { Components::TreeView.new }

    before do
      custom_field.reload
      hierarchy_page.add_custom_field_state(custom_field)
      visit custom_field_item_path(root.custom_field_id, gryffindor)
    end

    it "can navigate and keep the tab selection (regression #63921)", with_ee: [:custom_field_hierarchies] do
      # Expect items to be loaded and the tab nav to be selected correctly
      expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 2)
      hierarchy_page.expect_tab "Items"

      # Navigating to an item will keep the tab nav selection
      page.find_test_selector("op-custom-fields--hierarchy-item", text: "Hermione Granger").click
      hierarchy_page.expect_tab "Items"
    end

    it "can use the TreeView for navigation", with_ee: [:custom_field_hierarchies] do
      expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 2)

      # Expect the current item to be selected
      tree_view.should_have_active_item("Gryffindor")

      # All other nodes are collapsed initially
      tree_view.should_have_collapsed_node("Ravenclaw")

      # Navigate to another item
      tree_view.open_node "Ravenclaw"
      tree_view.click_node "Luna Lovegood"

      # Expect tree and page to update
      tree_view.should_have_active_item("Luna Lovegood")
      tree_view.should_have_open_node("Ravenclaw")
      tree_view.should_have_collapsed_node("Gryffindor")

      expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count: 0)
      hierarchy_page.expect_tab "Items"
    end
  end

  it_behaves_like "hierarchy custom fields on index page", "Work packages"

  context "with enterprise token", with_ee: [:custom_field_hierarchies] do
    it_behaves_like "expected fields for the custom field's format", "Work packages", "Hierarchy"
  end
end
