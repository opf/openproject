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

RSpec.describe "Saved related table queries", :js, with_ee: %i[edit_attribute_groups] do
  shared_let(:admin) { create(:admin) }
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }
  let!(:work_package) { create(:work_package, project:, type:) }
  let(:form_configuration) { type.default_variant.form_configuration }
  let(:query) { create(:query, user: admin, column_names: %w[id subject]) }
  let(:other_query) { create(:query, user: admin, column_names: %w[id subject status]) }

  before do
    query.add_filter("parent", "=", ["{id}"])
    query.save!
    other_query.add_filter("parent", "=", ["{id}"])
    other_query.save!
    form_configuration.update!(attribute_groups: [["Saved children", [query]], ["Other table", [other_query]]])
    login_as(admin)
    visit edit_form_configuration_path(form_configuration)
  end

  def within_table(name = "Saved children", &)
    within("[data-group-key='#{name}']", &)
  end

  def edit_table(name = "Saved children")
    within_table(name) { click_on accessible_name: "Edit query" }
    expect(page).to have_dialog("Work package table configuration")
  end

  it "refreshes and persists edited columns without changing another table" do
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end

    within_table do
      expect(page).to have_element(:dd, text: "Subject", exact_text: true)
      expect(page).to have_no_element(:dd, text: /\bID\b/)
    end
    within_table("Other table") do
      expect(page).to have_element(:dd, text: "ID, Subject, Status", exact_text: true)
    end

    visit current_path
    within_table { expect(page).to have_element(:dd, text: "Subject", exact_text: true) }
    within_table("Other table") do
      expect(page).to have_element(:dd, text: "ID, Subject, Status", exact_text: true)
    end
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_button(accessible_name: "Remove Subject")
      expect(page).to have_no_button(accessible_name: "Remove ID")
    end
  end

  def remove_id_column_from_saved_table
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end
    within_table { expect(page).to have_element(:dd, text: "Subject", exact_text: true) }
  end

  it "keeps an unsaved table open while another table's query is edited" do
    click_button "Add", exact: true
    find(:menuitem, "Related work packages table").click
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      wait_for_turbo_stream { click_button "Apply" }
    end
    fill_in "Section name", with: "Unsaved table"

    remove_id_column_from_saved_table

    expect(page).to have_field("Section name", with: "Unsaved table")
    click_button "Save", exact: true
    expect(page).to have_no_field("Section name")
    within_table("Unsaved table") { expect(page).to have_no_element(:dd, text: /\bID\b/) }
  end

  it "keeps another section's rename open while a query is edited" do
    within_table("Other table") { click_button accessible_name: "Section actions" }
    find(:menuitem, "Rename section").click
    fill_in "Section name", with: "Typed rename"

    remove_id_column_from_saved_table

    expect(page).to have_field("Section name", with: "Typed rename")
    click_button "Save", exact: true
    expect(page).to have_no_field("Section name")
    within_table("Typed rename") do
      expect(page).to have_element(:dd, text: "ID, Subject, Status", exact_text: true)
    end
  end

  it "keeps its own unsaved rename while its query is edited" do
    within_table { click_button accessible_name: "Section actions" }
    find(:menuitem, "Rename section").click
    fill_in "Section name", with: "Typed same-table rename"

    remove_id_column_from_saved_table

    expect(page).to have_field("Section name", with: "Typed same-table rename")
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_no_button(accessible_name: "Remove ID")
      click_button "Cancel"
    end
    click_button "Save", exact: true
    expect(page).to have_no_field("Section name")
    visit current_path
    within_table("Typed same-table rename") do
      expect(page).to have_element(:dd, text: "Subject", exact_text: true)
    end
  end

  it "discards its own unsaved rename when cancelled after its query is edited" do
    within_table { click_button accessible_name: "Section actions" }
    find(:menuitem, "Rename section").click
    fill_in "Section name", with: "Discarded rename"

    remove_id_column_from_saved_table

    click_link "Cancel"
    expect(page).to have_no_field("Section name")
    within_table { expect(page).to have_element(:dd, text: "Subject", exact_text: true) }
    visit current_path
    within_table { expect(page).to have_element(:dd, text: "Subject", exact_text: true) }
    expect(page).to have_no_css("[data-group-key='Discarded rename']")
  end

  it "discards cancelled edits and retains the saved query after reload" do
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      click_button accessible_name: "Remove ID"
      click_button "Cancel"
    end

    within_table { expect(page).to have_element(:dd, text: "ID, Subject", exact_text: true) }
    visit current_path
    within_table { expect(page).to have_element(:dd, text: "ID, Subject", exact_text: true) }
    edit_table
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Columns/i).click
      expect(page).to have_button(accessible_name: "Remove ID")
      expect(page).to have_button(accessible_name: "Remove Subject")
    end
  end

  it "keeps unavailable values after a rejected rename and allows further editing" do
    archived = create(:project, name: "Archived project")
    query.add_filter("project_id", "=", [project.id.to_s, archived.id.to_s])
    query.save!
    archived.update!(active: false)
    visit current_path

    expect(page).to have_text("Unavailable value")
    within_table { click_button accessible_name: "Section actions" }
    find(:menuitem, "Rename section").click
    fill_in "Section name", with: "   "
    click_button "Save", exact: true

    expect(page).to have_text("Group name can't be blank.")
    expect(page).to have_text("Unavailable value")
    fill_in "Section name", with: "Renamed children"
    click_button "Save", exact: true
    expect(page).to have_no_field("Section name")
    visit current_path
    within_table("Renamed children") { expect(page).to have_text("Unavailable value") }
    edit_table("Renamed children")
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Highlighting/i).click
      choose "No highlighting"
      wait_for_turbo_stream { click_button "Apply" }
    end
    expect(page).to have_no_dialog("Work package table configuration")
    visit current_path
    edit_table("Renamed children")
    within_dialog "Work package table configuration" do
      find(:role, :tab, accessible_name: /Highlighting/i).click
      expect(page).to have_checked_field("No highlighting")
    end
  end
end
