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

RSpec.describe "List custom field items administration", :js do
  shared_let(:admin) { create(:admin) }
  shared_let(:custom_field) { create(:list_wp_custom_field, name: "Fruit", possible_values: %w[pear apple]) }

  def item_row(label)
    page.find_test_selector("op-custom-fields--hierarchy-item", text: label)
  end

  def open_actions_for(label)
    within(item_row(label)) do
      find_test_selector("op-hierarchy-item--action-menu").click
    end
  end

  before do
    login_as(admin)
    visit custom_field_items_path(custom_field)
  end

  it "re-orders the entries alphabetically" do
    accept_confirm do
      click_on "Reorder values alphabetically"
    end

    expect(page).to have_xpath(
      "(//*[@data-test-selector='op-custom-fields--hierarchy-item'])[1]",
      text: "apple"
    )
  end

  it "marks an entry as the default value and clears it again" do
    open_actions_for("pear")
    click_on "Set as default value"

    expect(item_row("pear")).to have_text("Default")

    open_actions_for("pear")
    click_on "Clear default value"

    expect(page).to have_no_text("Default")
  end

  it "does not offer to nest entries" do
    open_actions_for("pear")

    expect(page).to have_link("Set as default value")
    expect(page).to have_no_link("Add sub-item")
    expect(page).to have_no_link("Change parent")
  end

  it "creates a new entry" do
    click_on "Item"
    fill_in "Item label", with: "banana"
    click_on "Save"

    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "banana")
  end

  it "edits an entry's label" do
    open_actions_for("pear")
    click_on "Edit"

    fill_in "Item label", with: "", fill_options: { clear: :backspace }
    fill_in "Item label", with: "peach"
    click_on "Save"

    expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: "peach")
    expect(page).to have_no_test_selector("op-custom-fields--hierarchy-item", text: "pear")
  end

  it "offers no short name input when creating an entry" do
    click_on "Item"

    expect(page).to have_test_selector("op-custom-fields--new-item-form")
    expect(page).to have_no_field("Short name")
  end

  it "offers no short name input when editing an entry" do
    open_actions_for("pear")
    click_on "Edit"

    expect(page).to have_field("Item label", with: "pear")
    expect(page).to have_no_field("Short name")
  end
end
