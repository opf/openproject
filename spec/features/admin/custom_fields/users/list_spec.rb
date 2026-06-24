# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"
require_relative "format_field_expectations"

RSpec.describe "users list custom fields", :js do
  let(:user) { create(:admin) }
  let(:section) { create(:user_custom_field_section, name: "Test section") }
  let(:cf_page) { Pages::Admin::Settings::UserCustomFields::Index.new }

  current_user { user }

  before { section }

  it "has the options in the right order" do
    cf_page.visit!
    cf_page.click_to_create_new_custom_field "List"

    fill_in "custom_field_name", with: "Operating System"
    select section.name, from: "custom_field_custom_field_section_id"
    check "multi_value"

    click_on "Save"

    expect(page).to have_text("Successful creation")
    expect(page).to have_field("multi_value", checked: true)

    click_link "Items"
    wait_for_network_idle

    expect(page).to have_css(".custom-option-row", count: 1)
    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Windows"
      find(".custom-option-default-value input").set true
    end

    retry_block do
      page.find_test_selector("add-custom-option").click
      expect(page).to have_css(".custom-option-row", count: 2)
    end

    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Linux"
    end

    retry_block do
      page.find_test_selector("add-custom-option").click
      expect(page).to have_css(".custom-option-row", count: 3)
    end

    within all(".custom-option-row").last do
      find(".custom-option-value input").set "Solaris"
      click_on accessible_name: "Move to top"
    end

    click_on "Save"

    expect(page).to have_css(".custom-option-row", count: 3)
    expect(page).to have_field("custom_field_custom_options_attributes_0_value", with: "Solaris")
    expect(page).to have_field("custom_field_custom_options_attributes_1_value", with: "Windows")
    expect(page).to have_field("custom_field_custom_options_attributes_2_value", with: "Linux")

    expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
    expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
    expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
  end

  it_behaves_like "expected fields for the User custom field's format", "List"
end
