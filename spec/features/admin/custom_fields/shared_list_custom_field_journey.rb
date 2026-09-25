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

# Includers define #open_new_list_field_form and #section (nil when the form has no section).
RSpec.shared_examples "list custom field journey" do
  def item_row(label) = page.find_test_selector("op-custom-fields--hierarchy-item", text: label)

  def item_at(position) = "(//*[@data-test-selector='op-custom-fields--hierarchy-item'])[#{position}]"

  def open_actions_for(label)
    within(item_row(label)) { find_test_selector("op-hierarchy-item--action-menu").click }
  end

  it "creates a multi-select list field and administers its entries" do
    open_new_list_field_form
    fill_in "custom_field_name", with: "Operating System"
    select section.name, from: "custom_field_custom_field_section_id" if section
    check "Allow multi-select"
    click_on "Save"

    expect(page).to have_text("Successful creation")
    expect(page).to have_checked_field("Allow multi-select")

    click_on "Items"
    within(page.find_test_selector("op-custom-fields--hierarchy-items-blankslate")) { click_on "Item" }
    fill_in "Item label", with: "Windows"
    click_on "Save"
    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "Windows")

    fill_in "Item label", with: "Linux"
    click_on "Save"
    expect(page).to have_xpath(item_at(2), text: "Linux")
    click_on "Cancel"
    expect(page).to have_no_field("Item label")

    open_actions_for("Linux")
    click_on "Move to top"
    expect(page).to have_xpath(item_at(1), text: "Linux")

    open_actions_for("Windows")
    click_on "Set as default value"
    expect(item_row("Windows")).to have_text("Default")
  end
end
