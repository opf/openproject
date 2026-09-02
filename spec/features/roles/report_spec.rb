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

require "rails_helper"

RSpec.describe "Roles report", :js do
  shared_let(:admin) { create(:admin) }
  let(:project) { create(:project, name: "Project 1", identifier: "project1") }
  let(:permissions) { %i[view_project permission1 permission2] }
  let!(:role1) { create(:global_role, permissions:, name: "Global IT MGMT") }
  let!(:role2) { create(:global_role, permissions:, name: "Unsure Off-Shore") }

  current_user { admin }

  before do
    visit report_roles_path
  end

  it "allows checking and unchecking by row", :selenium do
    expect(page).to have_heading "Permissions report"
    expect(page).to be_axe_clean
      .within("#content")
      .skipping("nested-interactive") # TODO: fix Collapsible Sections

    expect(page).to have_region "Project"

    within_region "Project" do
      expect(page).to have_selector :table, "Permissions matrix for Project module"

      expect(page).to have_unchecked_field "Assign Create projects permission to Global IT MGMT role"

      check "Assign Create projects permission to Global IT MGMT role"

      # mixed state
      expect(page).to have_checked_field "Assign Create projects permission to Global IT MGMT role"

      row = find(:row, "Create projects")
      row.click_on accessible_name: "Toggle Create projects permission for all roles"
      # stays checked
      expect(page).to have_checked_field "Assign Create projects permission to Global IT MGMT role"
      # mixed -> all checked
      expect(row.all(:checkbox, minimum: 1)).to all(match_selector(:checkbox, checked: true))

      row.click_on accessible_name: "Toggle Create projects permission for all roles"
      # all checked -> all unchecked
      expect(page).to have_unchecked_field "Assign Create projects permission to Global IT MGMT role"
      expect(row.all(:checkbox, minimum: 1)).to all(match_selector(:checkbox, unchecked: true))
    end

    click_on "Save"

    expect_and_dismiss_flash type: :success, message: "Successful update."
  end

  it "allows checking and unchecking by column" do
    expect(page).to have_heading "Permissions report"

    expect(page).to have_region "Project"

    within_region "Project" do
      expect(page).to have_selector :table, "Permissions matrix for Project module"

      expect(page).to have_unchecked_field "Assign Create projects permission to Global IT MGMT role"

      check "Assign Create projects permission to Global IT MGMT role"

      # mixed state
      expect(page).to have_checked_field "Assign Create projects permission to Global IT MGMT role"

      col_header = find("th", text: "GLOBAL IT MGMT")
      col_header.click_on accessible_name: "Toggle all Project permissions for Global IT MGMT role"

      # stays checked
      expect(page).to have_checked_field "Assign Create projects permission to Global IT MGMT role"
      # mixed -> all checked
      col_index = col_header.all(:xpath, "preceding-sibling::th").size + 1
      all_checkboxes = all("tbody tr td:nth-child(#{col_index})").flat_map { it.all(:checkbox, wait: 0) }
      expect(all_checkboxes).to all(match_selector(:checkbox, checked: true))

      col_header.click_on accessible_name: "Toggle all Project permissions for Global IT MGMT role"
      # all checked -> all unchecked
      expect(page).to have_unchecked_field "Assign Create projects permission to Global IT MGMT role"
      all_checkboxes = all("tbody tr td:nth-child(#{col_index})").flat_map { it.all(:checkbox, wait: 0) }
      expect(all_checkboxes).to all(match_selector(:checkbox, unchecked: true))
    end

    click_on "Save"

    expect_and_dismiss_flash type: :success, message: "Successful update."
  end

  it "allows checking and unchecking all" do
    expect(page).to have_heading "Permissions report"

    within("#project-section") do # FIXME: collapsible section semantics
      expect(page).to have_unchecked_field "Create projects"

      click_on "Check all"

      expect(page).to have_checked_field "Create projects"
      expect(all(:checkbox)).to all(match_selector(:checkbox, checked: true))

      click_on "Uncheck all"

      expect(page).to have_unchecked_field "Create projects"
      expect(all(:checkbox)).to all(match_selector(:checkbox, unchecked: true))
    end

    click_on "Save"

    expect_and_dismiss_flash type: :success, message: "Successful update."
  end
end
