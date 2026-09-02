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

RSpec.describe "Versions and categories admin settings" do
  shared_let(:admin) { create(:admin) }

  before do
    login_as(admin)
  end

  context "when the setting is off", with_settings: { work_package_multiple_versions: false } do
    before do
      visit "/admin/settings/versions_and_categories"
    end

    it "shows the sidebar entry" do
      expect(page).to have_css("#menu-sidebar .op-menu--item-title", text: "Versions and categories")
    end

    it "shows the warning banner with a link to more information" do
      expect(page).to have_text(
        "There are important upcoming changes to versions and categories. Please carefully review the following settings."
      )
      expect(page).to have_link(
        "More information",
        href: OpenProject::Static::Links.url_for(:multiple_versions_documentation)
      )
      expect(page).to have_css(
        "a.Button--invisible[target='_blank'][rel='noopener']",
        text: "More information"
      )
    end

    it "shows the target versions and categories subheads" do
      expect(page).to have_css("h3", text: "Target versions")
      expect(page).to have_css("h3", text: "Categories")
      expect(page).to have_css("h4", text: "Action required")
    end

    it "shows the planned changes for target versions" do
      expect(page).to have_text("The “Version” field will be renamed “Target versions”.")
      expect(page).to have_text(
        "This field is currently single-value. It will be converted to allow multiple values."
      )
      expect(page).to have_text(
        "This field is currently single-value. It will also be converted to allow multiple values."
      )
      expect(page).to have_text(
        "You can choose to manually run the conversion to enable multiple values before this automatic migration happens."
      )
    end

    it "shows the planned changes for categories" do
      expect(page).to have_text("The “Category” field will be renamed “Categories”.")
      expect(page).to have_text(
        "You will be able to choose to enable multiple values before this automatic conversion happens."
      )
    end

    it "shows the action required button" do
      expect(page).to have_link("Enable multiple values")
    end
  end

  context "when the setting is not writable",
          with_settings: { work_package_multiple_versions: false } do
    before do
      allow(Settings::Definition[:work_package_multiple_versions]).to receive(:writable?).and_return(false)
      visit "/admin/settings/versions_and_categories"
    end

    it "shows the not writable explanation instead of the enable button" do
      expect(page).to have_no_link("Enable multiple values")
      expect(page).to have_text(
        "These settings are configured via environment variables. " \
        "If you would like to manually run the conversion to enable multiple values before the automatic migration, " \
        "update your configuration.yml file."
      )
    end
  end

  context "when the setting is already on",
          with_settings: { work_package_multiple_versions: true } do
    before do
      visit "/admin/settings/versions_and_categories"
    end

    it "shows the recent changes notice with the documentation link" do
      expect(page).to have_css("h4", text: "Recent changes")
      expect(page).to have_text("The “Version” field has now been renamed “Target versions”.")
      expect(page).to have_text("The “Target versions” field now allows multiple values.")
      expect(page).to have_link(
        "our documentation",
        href: OpenProject::Static::Links.url_for(:multiple_versions_documentation)
      )
      expect(page).to have_no_link("Enable multiple values")
    end
  end

  context "when confirming the enable dialog", :js do
    before do
      Setting.work_package_multiple_versions = false

      visit "/admin/settings/versions_and_categories"
    end

    it "disables the confirm button until the checkbox is checked" do
      click_on "Enable multiple values"

      within "[role=alertdialog]" do
        expect(page).to have_button("Enable", disabled: true)

        find_field("I understand that this action is not reversible").click

        expect(page).to have_button("Enable", disabled: false, wait: 10)
      end
    end

    it "flips the setting synchronously and shows the success state" do
      click_on "Enable multiple values"

      within_dialog "Enable multiple target versions" do
        find_field("I understand that this action is not reversible").click
        click_button "Enable"
      end

      expect(page).to have_no_css("dialog")
      expect(page).to have_text("Recent changes", wait: 10)
      expect(page).to have_no_text("Enable multiple values")
      expect(Setting.find_by(name: "work_package_multiple_versions")).to have_attributes(value: true)
    end
  end
end
