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

RSpec.describe "color administration", :js do
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

      expect_and_dismiss_flash type: :error, message: /not a valid 6-digit hexadecimal color code/
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
