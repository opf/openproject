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

RSpec.describe "Related table drafts", :js, with_ee: %i[edit_attribute_groups] do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) { create(:work_package, project:, type:) }
  let(:form_configuration) { type.default_variant.form_configuration }

  before do
    login_as(admin)
    visit edit_form_configuration_path(form_configuration)
  end

  def add_table
    click_button "Add", exact: true
    find(:menuitem, "Related work packages table").click
    expect(page).to have_dialog("Work package table configuration", wait: 10)
    within_dialog("Work package table configuration") { wait_for_turbo_stream { click_button "Apply" } }
    expect(page).to have_field("Section name")
    expect(page).to have_element(:dt, text: "Relation type")
    expect(page).to have_element(:dd, text: "Children")
  end

  def edit_table
    within("[data-group-type=query]") { click_on accessible_name: "Edit query" }
    expect(page).to have_dialog("Work package table configuration")
  end

  def save_table(name)
    fill_in "Section name", with: name
    click_button "Save", exact: true
    expect(page).to have_no_field("Section name")
    expect(page).to have_text(name)
  end

  it "edits highlighting before saving the table" do
    add_table
    edit_table

    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Highlighting/i).click
      choose "No highlighting"
      wait_for_turbo_stream { click_button "Apply" }
    end
    expect(page).to have_no_dialog("Work package table configuration")

    save_table("Draft children")
    visit current_path
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Highlighting/i).click
      expect(page).to have_checked_field("No highlighting")
    end
  end

  it "refreshes draft columns while preserving the typed name" do
    add_table
    fill_in "Section name", with: "Selected columns"
    edit_table

    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end

    expect(page).to have_field("Section name", with: "Selected columns")
    expect(page).to have_no_element(:dd, text: /\bID\b/)
    expect(page).to have_element(:dd, text: "Subject")
    save_table("Selected columns")
    visit current_path
    expect(page).to have_no_element(:dd, text: /\bID\b/)
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_no_button(accessible_name: "Remove ID")
      expect(page).to have_button(accessible_name: "Remove Subject")
    end
  end

  it "cancels editor changes and discards the whole draft without persisting it" do
    original_groups = form_configuration.attribute_groups.map(&:key)
    original_queries = Query.count
    add_table
    edit_table

    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      click_button "Cancel"
    end

    expect(page).to have_element(:dd, text: /\bID\b/)
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_button(accessible_name: "Remove ID")
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end
    expect(page).to have_no_element(:dd, text: /\bID\b/)
    click_link "Cancel", exact: true

    expect(page).to have_no_field("Section name")
    expect(page).to have_no_button("Related work packages table")
    expect(form_configuration.reload.attribute_groups.map(&:key)).to eq(original_groups)
    expect(Query.count).to eq(original_queries)
    visit current_path
    expect(page).to have_button("Add", exact: true)
    expect(page).to have_no_button("Related work packages table")
  end

  it "retains query settings after a rejected name and permits correction" do
    add_table
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end
    fill_in "Section name", with: "People"
    click_button "Save", exact: true

    expect(page).to have_text("Group names must be unique.")
    expect(page).to have_field("Section name", with: "People")
    expect(page).to have_no_element(:dd, text: /\bID\b/)
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_no_button(accessible_name: "Remove ID")
      wait_for_turbo_stream { click_button "Apply" }
    end
    expect(page).to have_field("Section name", with: "People")
    save_table("New children")
    visit current_path
    expect(page).to have_text("New children")
    expect(page).to have_no_element(:dd, text: /\bID\b/)
  end
end
