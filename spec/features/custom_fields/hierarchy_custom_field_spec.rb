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
require "support/pages/custom_fields/hierarchy_page"

RSpec.describe "custom fields of type hierarchy", :js, :with_cuprite do
  let(:user) { create(:admin) }
  let(:custom_field_index_page) { Pages::CustomFields::IndexPage.new }
  let(:new_custom_field_page) { Pages::CustomFields::NewPage.new }
  let(:hierarchy_page) { Pages::CustomFields::HierarchyPage.new }

  it "lets you create, update and delete a custom field of type hierarchy",
     with_flag: { custom_field_of_type_hierarchy: true } do
    login_as user

    # First, we create a new custom field of type hierarchy
    custom_field_index_page.visit!

    click_on "New custom field"
    new_custom_field_page.expect_current_path

    hierarchy_name = "Stormtrooper Organisation"
    fill_in "Name", with: hierarchy_name
    select "Hierarchy", from: "Format"
    click_on "Save"

    custom_field_index_page.expect_current_path("tab=WorkPackageCustomField")
    expect(page).to have_list_item(hierarchy_name)

    # The next step is to enter the custom field and work on it
    CustomField.find_by(name: hierarchy_name).tap do |custom_field|
      hierarchy_page.add_custom_field_state(custom_field)
    end

    click_on hierarchy_name
    hierarchy_page.expect_current_path

    hierarchy_page.expect_empty_items_banner(visible: true)
    hierarchy_page.expect_header_text(hierarchy_name)

    # Changing the name is possible
    hierarchy_name = "Imperial Organisation"
    fill_in "Name", with: "", fill_options: { clear: :backspace }
    fill_in "Name", with: hierarchy_name
    click_on "Save"
    hierarchy_page.expect_header_text(hierarchy_name)

    # Now we want to create hierarchy items
    hierarchy_page.switch_tab "Items"
    hierarchy_page.expect_current_path
    hierarchy_page.expect_blank_slate(visible: true)

    click_on "Item"
    hierarchy_page.expect_blank_slate(visible: false)
    fill_in "Label", with: "Stormtroopers"
    fill_in "Short", with: "ST"
    click_on "Save"
    hierarchy_page.expect_blank_slate(visible: false)
    hierarchy_page.expect_items_count(1)
    hierarchy_page.expect_hierarchy_item(label: "Stormtroopers", short: "(ST)")

    # Is the form cancelable?
    click_on "Item"
    hierarchy_page.expect_inline_form(visible: true)
    fill_in "Label", with: "Dark Troopers"
    click_on "Cancel"
    hierarchy_page.expect_inline_form(visible: false)
    hierarchy_page.expect_items_count(1)
    hierarchy_page.expect_hierarchy_item(label: "Dark Troopers", visible: false)

    # What happens if I add a wrong item?
    click_on "Item"
    fill_in "Label", with: "Phoenix Squad"
    click_on "Save"
    hierarchy_page.expect_items_count(2)
    hierarchy_page.expect_hierarchy_item(label: "Phoenix Squad", visible: true)
    hierarchy_page.open_action_menu_for("Phoenix Squad")
    click_on "Delete"
    hierarchy_page.expect_deletion_dialog(visible: true)
    click_on "Delete"
    hierarchy_page.expect_deletion_dialog(visible: false)
    hierarchy_page.expect_items_count(1)
    hierarchy_page.expect_hierarchy_item(label: "Phoenix Squad", visible: false)

    # Can I cancel the deletion?
    hierarchy_page.open_action_menu_for("Stormtroopers")
    click_on "Delete"
    hierarchy_page.expect_deletion_dialog(visible: true)
    click_on "Cancel"
    hierarchy_page.expect_deletion_dialog(visible: false)
    hierarchy_page.expect_hierarchy_item(label: "Stormtroopers", visible: true)

    # And is the blue banner gone, now that I have added some items?
    hierarchy_page.switch_tab "Details"
    hierarchy_page.expect_empty_items_banner(visible: false)

    # Finally, we delete the custom field ... I'm done with this ...
    custom_field_index_page.visit!
    expect(page).to have_list_item(hierarchy_name)
    within("tr", text: hierarchy_name) { accept_prompt { click_on "Delete" } }
    expect(page).to have_no_text(hierarchy_name)
  end
end
