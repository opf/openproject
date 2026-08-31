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

RSpec.describe "work package list custom fields", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }

  before do
    login_as user
  end

  describe "editing an existing list custom field" do
    let!(:custom_field) do
      create(
        :list_wp_custom_field,
        name: "Platform",
        possible_values: %w[Playstation Xbox Nintendo PC]
      )
    end

    before do
      cf_page.visit!
      wait_for_reload

      click_on custom_field.name
      wait_for_reload

      click_link "Items"
      wait_for_reload
    end

    it "adds new options" do
      retry_block do
        page.find_test_selector("add-custom-option").click

        expect(page).to have_css(".custom-option-row", count: 5)
      end

      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Sega"
      end

      retry_block do
        page.find_test_selector("add-custom-option").click

        expect(page).to have_css(".custom-option-row", count: 6)
      end

      within all(".custom-option-row").last do
        find(".custom-option-value input").set "Atari"
      end

      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")
      expect(page).to have_css(".custom-option-row", count: 6)

      %w[Playstation Xbox Nintendo PC Sega Atari].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end
    end

    it "updates the values and orders of the custom options" do
      expect(page).to have_text("Platform")

      expect(page).to have_css(".custom-option-row", count: 4)
      %w[Playstation Xbox Nintendo PC].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      fill_in("custom_field_custom_options_attributes_1_value", with: "")
      fill_in("custom_field_custom_options_attributes_1_value", with: "Sega")
      check("custom_field_custom_options_attributes_0_default_value")
      check("custom_field_custom_options_attributes_2_default_value")
      within first(".custom-option-row") do
        click_on accessible_name: "Move to bottom"
      end
      click_on "Save"

      expect(page).to have_text("Successful update")
      expect(page).to have_text("Platform")

      %w[Sega Nintendo PC Playstation].each_with_index do |value, i|
        expect(page).to have_field("custom_field_custom_options_attributes_#{i}_value", with: value)
      end

      expect(page).to have_field("custom_field_custom_options_attributes_0_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_1_default_value", checked: true)
      expect(page).to have_field("custom_field_custom_options_attributes_2_default_value", checked: false)
      expect(page).to have_field("custom_field_custom_options_attributes_3_default_value", checked: false)
    end

    it "shows the correct breadcrumbs" do
      page.within_test_selector("custom-fields--page-header") do
        expect(page).to have_css(".breadcrumb-item", text: "Work packages")
        expect(page).to have_css(".breadcrumb-item.breadcrumb-item-selected", text: "Platform")
      end
    end

    context "with work packages using the options" do
      before do
        create_list(
          :work_package_custom_value,
          3,
          custom_field:,
          value: custom_field.custom_options[1].id
        )
      end

      it "deletes a custom option and all values using it" do
        within all(".custom-option-row")[1] do
          accept_alert do
            find(".icon-delete").click
          end
        end

        expect(page).to have_text("Option 'Xbox' and its 3 occurrences were deleted.")

        rows = all(".custom-option-value input")

        expect(rows.size).to be(3)

        expect(rows[0].value).to eql("Playstation")
        expect(rows[1].value).to eql("Nintendo")
        expect(rows[2].value).to eql("PC")
      end
    end
  end
end
