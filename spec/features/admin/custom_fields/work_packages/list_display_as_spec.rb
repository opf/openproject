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

RSpec.describe "Display as setting of list custom fields", :js do
  shared_let(:admin) { create(:admin) }

  let(:index_cf_page) { Pages::CustomFields::Index.new }

  current_user { admin }

  it "displays a multi-select list as checkboxes and falls back to the dropdown when multi-select is turned off" do
    index_cf_page.visit!
    index_cf_page.click_to_create_new_custom_field("List")

    fill_in "custom_field_name", with: "Platforms"
    check "Allow multi-select"
    select "Checkboxes (multi-select only)", from: "Display as"
    click_on "Save"

    index_cf_page.expect_flash(message: "Successful creation.")

    custom_field = CustomField.find_by!(name: "Platforms")
    expect(custom_field).to have_attributes(multi_value: true, display_as: "checkboxes")

    visit edit_custom_field_path(custom_field)

    expect(page).to have_select("Display as", selected: "Checkboxes (multi-select only)")
    uncheck "Allow multi-select"
    click_on "Save"

    index_cf_page.expect_flash(message: "Successful update.")
    expect(page).to have_select("Display as", selected: "Dropdown")
    expect(custom_field.reload).to have_attributes(multi_value: false, display_as: nil)
  end

  it "rejects radio buttons for a multi-select list" do
    index_cf_page.visit!
    index_cf_page.click_to_create_new_custom_field("List")

    fill_in "custom_field_name", with: "Severity"
    check "Allow multi-select"
    select "Radio buttons (single-select only)", from: "Display as"
    click_on "Save"

    expect(page).to have_text("can only be radio buttons when multi-select is not allowed.")
    expect(CustomField.find_by(name: "Severity")).to be_nil
  end
end
