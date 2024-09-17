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

RSpec.describe "Projects index page", :js, :with_cuprite, with_settings: { login_required?: false } do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:admin) { create(:admin) }

  let(:modal) { Components::WorkPackages::TableConfigurationModal.new }
  let(:model_filters) { Components::WorkPackages::TableConfiguration::Filters.new }
  let(:columns) { Components::WorkPackages::Columns.new }
  let(:filters) { Components::WorkPackages::Filters.new }
  let(:wp_table) { Pages::WorkPackagesTable.new }
  let(:projects_page) { Pages::Projects::Index.new }
  let(:dropdown) { Components::ProjectIncludeComponent.new }

  before do
    login_as admin
  end

  describe "with no projects on index" do
    it "does not show the Gantt menu entry" do
      visit projects_path

      projects_page.open_filters
      projects_page.filter_by_active("yes")
      page.find('[data-test-selector="project-more-dropdown-menu"]').click

      projects_page.expect_gantt_menu_entry(visible: false)
    end
  end

  describe "with only an archived project on index" do
    let!(:project) { create(:project, active: false) }

    it "does not show the Gantt menu entry" do
      visit projects_path
      page.find('[data-test-selector="project-more-dropdown-menu"]').click
      projects_page.expect_gantt_menu_entry(visible: false)
    end
  end

  describe "with projects defined" do
    let!(:string_cf) { create(:string_project_custom_field, name: "Foobar") }

    let(:cv_a) { build(:custom_value, custom_field: string_cf, value: "A") }
    let(:cv_b) { build(:custom_value, custom_field: string_cf, value: "B") }

    let!(:project_a) { create(:project, name: "A", types: [type_milestone], custom_values: [cv_a]) }
    let!(:project_b) { create(:project, name: "B", types: [type_milestone], custom_values: [cv_b]) }

    let!(:type_milestone) { create(:type, name: "Milestone", is_milestone: true) }

    let!(:work_package_a) { create(:work_package, subject: "WP A", type: type_milestone, project: project_a) }
    let!(:work_package_b) { create(:work_package, subject: "WP B", type: type_milestone, project: project_b) }

    it "can manage and browse the project portfolio Gantt" do
      visit admin_settings_projects_path

      page.all(".op-draggable-autocomplete--item", text: /^(?!Name).*$/).each do |item| # rubocop:disable Rails/FindEach
        item.find(".op-draggable-autocomplete--remove-item").click
      end

      ["Status", string_cf.name].each do |column|
        select_autocomplete find(".op-draggable-autocomplete--input"),
                            results_selector: ".ng-dropdown-panel-items",
                            query: column
      end

      # Edit the project gantt query
      scroll_to_and_click(find("button", text: "Edit query"))

      columns.assume_opened
      columns.uncheck_all save_changes: false
      columns.add "ID", save_changes: false
      columns.add "Subject", save_changes: false
      columns.add "Project", save_changes: false

      modal.switch_to "Filters"

      model_filters.expect_filter_count 2
      # Add a project filter that gets overridden
      model_filters.add_filter_by("Project", "is (OR)", project_a.name)

      model_filters.expect_filter_by("Type", "is (OR)", type_milestone.name)
      model_filters.save

      # Save the page
      scroll_to_and_click(find(".button", text: "Save"))

      expect(page).to have_css(".op-toast.-success", text: "Successful update.")

      RequestStore.clear!
      query = JSON.parse Setting.project_gantt_query
      expect(query["f"]).to include({ "n" => "type", "o" => "=", "v" => [type_milestone.id.to_s] })

      # Go to project page
      visit projects_path

      # Click the gantt from more menu button
      page.find('[data-test-selector="project-more-dropdown-menu"]').click
      new_window = window_opened_by { click_on "Open as Gantt view" }
      switch_to_window new_window

      wp_table.expect_work_package_listed work_package_a, work_package_b

      # Expect grouped and filtered for both projects
      expect(page).to have_css ".group--value", text: "A"
      expect(page).to have_css ".group--value", text: "B"

      # Expect type and project filters
      dropdown.expect_count 2
      filters.expect_filter_count 1
      filters.open

      filters.expect_filter_by("Type", "is (OR)", [type_milestone.name])

      # Expect columns
      columns.open_modal
      columns.expect_checked "ID"
      columns.expect_checked "Subject"
      columns.expect_checked "Project"

      columns.expect_unchecked "Assignee"
      columns.expect_unchecked "Type"
      columns.expect_unchecked "Priority"
    end
  end
end
