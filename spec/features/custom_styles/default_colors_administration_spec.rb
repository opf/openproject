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

RSpec.describe "default colors administration", :js do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)

    visit custom_style_path(tab: :default_colors)
  end

  describe "listing colors" do
    it "shows no results by default" do
      expect(page).to have_text(I18n.t(:"colors.index.no_results_title_text"))

      click_link accessible_name: "New color"
    end

    it "is described" do
      expect(page).to have_text(I18n.t("admin.custom_styles.default_colors.description"))
    end
  end

  describe "contrast previews" do
    before do
      click_link accessible_name: "New color"
      fill_in "Name", with: "Preview color"
    end

    it "shows pass or fail per theme and usage" do
      fill_in "Hex code", with: "#fff"
      find_field("Name").click

      expect(page).to have_heading "Contrast preview"
      expect(page).to have_text("standard light and dark themes")
      expect(page).to have_text("3 of 4 pass")
      within(:list, accessible_name: "Light mode") do
        within(:list_item, text: "Used as foreground") do
          expect(page).to have_text("#C7C7C7")
          expect(page).to have_text("1.69:1")
          expect(page).to have_text("Fail")
        end
        within(:list_item, text: "Used as background") do
          expect(page).to have_text("21.00:1")
          expect(page).to have_text("Pass")
        end
      end
      within(:list, accessible_name: "Dark mode") do
        within(:list_item, text: "Used as foreground") do
          expect(page).to have_text("#0D1117")
          expect(page).to have_text("18.92:1")
          expect(page).to have_text("Pass")
        end
        within(:list_item, text: "Used as background") do
          expect(page).to have_text("#393C41")
          expect(page).to have_text("11.11:1")
          expect(page).to have_text("Pass")
        end
      end
      expect(Color.where(name: "Preview color")).not_to exist
    end

    it "hides results for incomplete input and rejects an invalid hex code on blur" do
      fill_in "Hex code", with: "#fff"
      find_field("Name").click
      expect(page).to have_heading "Contrast preview"

      find_field("Hex code").send_keys(:end, :backspace)
      expect(page).to have_no_heading "Contrast preview"
      expect(page).to have_field("Hex code", validation_error: false)
      find_field("Name").click
      expect(page).to have_field("Hex code", validation_error: "Hex code is not a valid 6-digit hexadecimal color code.")
      expect(page).to have_no_heading "Contrast preview"

      fill_in "Hex code", with: "#fff"
      expect(page).to have_field("Hex code", validation_error: false)
      find_field("Name").click
      expect(page).to have_heading "Contrast preview"
    end

    it "saves a color that fails contrast and previews it again after reopening" do
      fill_in "Hex code", with: "#fff"
      find_field("Name").click
      click_on "Save"
      wait_for_reload
      expect_and_dismiss_flash type: :success, message: "Successful creation."

      within_test_selector "default-colors-list" do
        click_on "Preview color"
      end
      expect(page).to have_heading "Contrast preview"
      expect(page).to have_text("3 of 4 pass")
    end

    it "checks contrast when a color is picked" do
      fill_in "Name", with: "Picked color"
      fill_in accessible_name: "Pick color for Hex code", with: "#ff0000"

      expect(page).to have_field("Hex code", with: "#FF0000")
      expect(page).to have_heading "Contrast preview"
    end

    it "clears the server error when the hex code is edited" do
      fill_in "Name", with: "Invalid color"
      fill_in "Hex code", with: "#XXX"
      click_on "Save"

      expect(page).to have_field("Hex code", validation_error: "Hex code is not a valid 6-digit hexadecimal color code.")

      find_field("Hex code").send_keys(:end, :backspace)

      expect(page).to have_field("Hex code", validation_error: false)
      expect(page).to have_no_text("Hex code is not a valid 6-digit hexadecimal color code.")
    end

    it "shows the client hex code error where the server shows it" do
      fill_in "Hex code", with: "#XXX"
      find_field("Name").click

      expect(page).to have_css(".FormControl-inlineValidation",
                               text: "Hex code is not a valid 6-digit hexadecimal color code.", count: 1)
    end

    it "checks contrast while typing without leaving the field" do
      fill_in "Hex code", with: ""
      expect(page).to have_no_heading "Contrast preview"

      find_field("Hex code").send_keys("#fff")

      expect(find_field("Hex code")).to match_css(":focus")
      expect(page).to have_heading "Contrast preview"
    end
  end

  describe "creating colors" do
    it "creates a color" do
      click_link accessible_name: "New color"

      fill_in "Name", with: "Vibrant pink"
      fill_in "Hex code", with: "#FF69B4"

      click_on "Save"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      within_test_selector "default-colors-list" do
        expect(page).to have_link "Vibrant pink"
      end
    end

    it "displays validation errors if color values are invalid" do
      click_link accessible_name: "New color"

      fill_in "Name", with: "Not so vibrant pink"
      fill_in "Hex code", with: "11"

      click_on "Save"

      expect(page).to have_text("not a valid 6-digit hexadecimal color code")
    end
  end

  describe "updating colors" do
    it "creates and updates a color" do
      click_link accessible_name: "New color"

      fill_in "Name", with: "Dark Purple"
      fill_in "Hex code", with: "#301934"

      click_on "Save"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      within_test_selector "default-colors-list" do
        click_on "Dark Purple"
      end

      expect(page).to have_heading "Dark Purple"

      fill_in "Name", with: "Dark Grape (web safe)"
      fill_in "Hex code", with: "330033"

      click_on "Save"

      expect_and_dismiss_flash type: :success, message: "Successful update."

      within_test_selector "default-colors-list" do
        expect(page).to have_link "Dark Grape (web safe)"
      end
    end
  end

  describe "deleting colors" do
    it "creates and deletes a color" do
      click_link accessible_name: "New color"

      fill_in "Name", with: "Dark Purple"
      fill_in "Hex code", with: "#301934"

      click_on "Save"

      expect_and_dismiss_flash type: :success, message: "Successful creation."

      within_test_selector "default-colors-list" do
        click_on "Dark Purple"
      end

      expect(page).to have_heading "Dark Purple"

      within ".PageHeader-actions" do
        accept_confirm do
          click_on "Delete"
        end
      end

      expect_and_dismiss_flash type: :success, message: "Successful deletion."
    end
  end
end
