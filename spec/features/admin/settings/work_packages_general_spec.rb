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

RSpec.describe "Work packages general admin settings", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  current_user { admin }

  before do
    Setting.cross_project_work_package_relations = true
    Setting.display_subprojects_work_packages = true
    Setting.work_package_startdate_is_adddate = false
    Setting.work_package_list_default_highlighting_mode = "inline"
    Setting.work_package_list_default_columns = %w[id subject status priority]
  end

  it "allows to change general settings" do
    visit admin_settings_work_packages_general_path

    expect(page).to have_checked_field "Allow cross-project work package relations"
    expect(page).to have_checked_field "Display subprojects work packages in main projects by default"
    expect(page).to have_unchecked_field "Use current date as start date for new work packages"
    expect(page).to have_select "Default highlighting mode", selected: "Highlight attribute(s) inline"
    expect(page).to have_element("fieldset", text: "Default inline highlighted attributes")
    within_fieldset "Default inline highlighted attributes" do
      expect(page).to have_checked_field "Status"
      expect(page).to have_checked_field "Priority"
      expect(page).to have_checked_field "Finish date"
    end

    uncheck "Allow cross-project work package relations"
    uncheck "Display subprojects work packages in main projects by default"
    check "Use current date as start date for new work packages"
    within_fieldset "Default inline highlighted attributes" do
      uncheck "Priority"
      uncheck "Finish date"
    end
    click_on "Save"

    expect_and_dismiss_flash(message: "Successful update")

    # Check that we persist the right key
    expect(Setting.work_package_list_default_highlighted_attributes).to eq(["status"])

    expect(page).to have_unchecked_field "Allow cross-project work package relations"
    expect(page).to have_unchecked_field "Display subprojects work packages in main projects by default"
    expect(page).to have_checked_field "Use current date as start date for new work packages"
    expect(page).to have_select "Default highlighting mode", selected: "Highlight attribute(s) inline"
    expect(page).to have_element("fieldset", text: "Default inline highlighted attributes")
    within_fieldset "Default inline highlighted attributes" do
      expect(page).to have_checked_field "Status"
      expect(page).to have_unchecked_field "Priority"
      expect(page).to have_unchecked_field "Finish date"
    end

    select "Entire row by Priority", from: "Default highlighting mode"
    expect(page).to have_no_element("fieldset", text: "Default inline highlighted attributes")
    click_on "Save"

    expect_and_dismiss_flash(message: "Successful update")
    expect(page).to have_select "Default highlighting mode", selected: "Entire row by Priority"
    expect(page).to have_no_element("fieldset", text: "Default inline highlighted attributes")

    # NOTE: The list of inline options keeps the last stored selection
    select "Highlight attribute(s) inline", from: "Default highlighting mode"
    expect(page).to have_element("fieldset", text: "Default inline highlighted attributes")
    within_fieldset "Default inline highlighted attributes" do
      expect(page).to have_checked_field "Status"
      expect(page).to have_unchecked_field "Priority"
      expect(page).to have_unchecked_field "Finish date"
    end

    within_fieldset "Default inline highlighted attributes" do
      uncheck "Status"
    end
    click_on "Save"

    expect_and_dismiss_flash(message: "Successful update")
    expect(page).to have_select "Default highlighting mode", selected: "Highlight attribute(s) inline"
    expect(page).to have_element("fieldset", text: "Default inline highlighted attributes")
    within_fieldset "Default inline highlighted attributes" do
      expect(page).to have_unchecked_field "Status"
      expect(page).to have_unchecked_field "Priority"
      expect(page).to have_unchecked_field "Finish date"
    end

    # Check that the settings are persisted
    RequestStore.clear!
    expect(Setting.cross_project_work_package_relations).to be(false)
    expect(Setting.display_subprojects_work_packages).to be(false)
    expect(Setting.work_package_startdate_is_adddate).to be(true)
    expect(Setting.work_package_list_default_highlighting_mode).to eq("inline")
    expect(Setting.work_package_list_default_highlighted_attributes).to eq([])
  end

  it "allows to change work package list columns" do
    project = create(:project)
    work_package = create(:work_package, project:)

    visit admin_settings_work_packages_general_path

    within_fieldset "Default work package lists columns" do
      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[ID Subject Status Priority]

      status_item = page.find(".op-draggable-autocomplete--item", text: "Status", exact_text: true)
      status_item.find(".op-draggable-autocomplete--remove-item").click

      # NOTE: ID item cannot be removed
      id_item = page.find(".op-draggable-autocomplete--item", text: "ID", exact_text: true)
      expect(id_item).to have_no_element(".op-draggable-autocomplete--remove-item")

      add_columns = page.find(:combo_box, "Add columns")
      select_autocomplete add_columns.ancestor("ng-select"), query: "Author", results_selector: "body"

      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[ID Subject Priority Author]
    end

    click_on "Save"
    expect_and_dismiss_flash(message: "Successful update")
    within_fieldset "Default work package lists columns" do
      items = page.all(".op-draggable-autocomplete--item")
      expect(items.map(&:text)).to eq %w[ID Subject Priority Author]
    end

    # Check the effect of the settings change on the work packages table
    wp_table_page = Pages::WorkPackagesTable.new
    wp_table_page.visit!
    wp_table_page.expect_work_package_listed(work_package)
    expect(page.all("th.wp-table--table-header").pluck("aria-label")).to eq %w[ID Subject Priority Author Project]
  end
end
