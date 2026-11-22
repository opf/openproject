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

require "rails_helper"

RSpec.describe "Project dashboard pages", :skip_csrf, type: :rails_request do
  let(:project) { create(:project, public: false) }
  let(:destination) { create(:project, public: false) }
  let(:restricted) { create(:project, public: false) }
  let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[manage_dashboards],
             destination => %i[manage_dashboards],
             restricted => %i[]
           })
  end

  let(:standard) { Grids::DashboardPage.create!(name: "Progress Report", row_count: 1, column_count: 1) }

  current_user { user }

  before do
    standard.dashboard_page_assignments.create!(project:)
    standard.dashboard_page_assignments.create!(project: destination)
    create(:grid_widget, grid: standard, identifier: "custom_text",
                         start_row: 1, end_row: 2, start_column: 1, end_column: 2,
                         options: { "text" => "Release summary" })
  end

  it "adds a local dashboard tab without changing Project Overview" do
    get new_project_dashboard_page_path(project), headers: { "Accept" => Mime[:turbo_stream].to_s }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("new-dashboard-dialog", 'name="dashboard_page[name]"')

    post project_dashboard_pages_path(project), params: { dashboard_page: { name: "Delivery" } }

    page = Grids::DashboardPage.find_by!(project:, name: "Delivery")
    expect(response).to redirect_to(project_dashboard_page_path(project, page))
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Delivery", "Progress Report", "Edit dashboard in project settings")
  end

  it "links to dashboard settings and applies the saved tab order only in the current project" do
    local = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1)
    settings_path = settings_project_dashboard_pages_path(project)

    get dashboard_project_overview_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("page-header a[href='#{settings_path}']")).to be_present

    type = Overviews::DashboardTabs::SORTABLE_LIST_TYPE
    put project_move_dashboard_tab_path(project, local.id), params: { list_type: type, prev_id: "" }
    expect(response).to have_http_status(:no_content)
    put project_move_dashboard_tab_path(project, standard.id), params: { list_type: type, prev_id: local.id }
    expect(response).to have_http_status(:no_content)

    put project_move_dashboard_tab_path(project, standard.id),
        params: { list_type: type, prev_id: standard.id },
        headers: { "Accept" => Mime[:turbo_stream].to_s }
    expect(response).to have_http_status(:unprocessable_entity)

    get settings_path
    keys = response.parsed_body.css("[data-dashboard-tab-key]").pluck("data-dashboard-tab-key")
    expect(keys).to eq([local.id.to_s, standard.id.to_s, "original"])

    get project_overview_path(project)
    paths = [project_dashboard_page_path(project, local), project_dashboard_page_path(project, standard),
             dashboard_project_overview_path(project)]
    links = response.parsed_body.css('[data-test-selector="overview-tabs"] a').pluck("href")
    expect(links.intersection(paths)).to eq(paths)

    get settings_project_dashboard_pages_path(destination)
    keys = response.parsed_body.css("[data-dashboard-tab-key]").pluck("data-dashboard-tab-key")
    expect(keys).to eq(["original", standard.id.to_s])
  end

  it "links to dashboard editors and shows project counts and types" do
    local = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1)
    inactive = Grids::DashboardPage.create!(project:, name: "Archived report", row_count: 1, column_count: 1, disabled: true)

    get settings_project_dashboard_pages_path(project)

    document = response.parsed_body
    expect(document.css("segmented-control a").map { |link| link.text.strip }).to eq(["All", "Standard", "Project specific"])
    expect(document.at_css("input#project-dashboard-name-search")).to be_present
    original_row = document.at_css("[data-dashboard-tab-key='original']")
    expect(original_row.at_css("a[href='#{project_edit_settings_original_dashboard_path(project)}']")).to be_present
    local_row = document.at_css("[data-dashboard-tab-key='#{local.id}']")
    expect(local_row.at_css("a[href='#{project_edit_settings_dashboard_page_path(project, local)}']")).to be_present
    expect(local_row.at_css("[data-sortable-lists--item-target='handle']")).to be_present
    expect(local_row.at_css("[role='cell'].projects").text.split.last).to eq("1")
    standard_row = document.at_css("[data-dashboard-tab-key='#{standard.id}']")
    expect(standard_row.at_css("[role='rowheader'] a")).to be_nil
    expect(standard_row.at_css(".Label").text).to eq("Standard")
    expect(standard_row.at_css("[role='cell'].projects").text.split.last).to eq("2")
    expect(document.at_css("[data-dashboard-tab-key='#{inactive.id}'] [role='rowheader'] a")).to be_nil
  end

  it "combines the dashboard type filter with the name quick filter" do
    local = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1)
    inactive = Grids::DashboardPage.create!(project:, name: "Archived report", row_count: 1, column_count: 1, disabled: true)

    get settings_project_dashboard_pages_path(project, dashboard_type: "standard")
    document = response.parsed_body
    expect(document.css("[data-dashboard-tab-key]").pluck("data-dashboard-tab-key")).to eq([standard.id.to_s])
    expect(document.at_css("segmented-control .SegmentedControl-item--selected").text.strip).to eq("Standard")
    expect(document.at_css("[data-sortable-lists--item-target='handle']")).to be_nil

    get settings_project_dashboard_pages_path(project, dashboard_type: "project")
    expect(response.parsed_body.css("[data-dashboard-tab-key]").pluck("data-dashboard-tab-key"))
      .to contain_exactly("original", local.id.to_s, inactive.id.to_s)

    filters = [{ name: { operator: "~", values: ["DELIVE"] } }].to_json
    get settings_project_dashboard_pages_path(project, dashboard_type: "project", filters:),
        headers: { "Turbo-Frame" => "project-dashboard-list" }
    document = response.parsed_body
    expect(document.at_css("turbo-frame#project-dashboard-list")).to be_present
    expect(document.css("[data-dashboard-tab-key]").pluck("data-dashboard-tab-key")).to eq([local.id.to_s])
    expect(document.at_css("[data-sortable-lists--item-target='handle']")).to be_nil
  end

  it "renders the widget editor in project settings" do
    dashboard = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1)

    get project_edit_settings_dashboard_page_path(project, dashboard)

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css('input[name="dashboard_page[name]"]')).to be_nil
    expect(document.at_css("opce-dashboard[data-grid-id='#{dashboard.id}']")).to be_present

    get project_edit_settings_original_dashboard_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("opce-dashboard")["data-project-identifier"]).to eq(project.identifier.to_json)
  end

  it "lets project managers deactivate and reactivate a standard dashboard for one project" do
    patch deactivate_project_dashboard_page_path(project, standard)
    expect(response).to redirect_to(project_overview_path(project))

    get project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:not_found)
    get project_dashboard_page_path(destination, standard)
    expect(response).to have_http_status(:ok)

    get settings_project_dashboard_pages_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("[data-test-selector='toggle-standard-dashboard-#{standard.id}']")).to be_present

    patch activate_project_dashboard_page_path(project, standard)
    expect(response).to redirect_to(settings_project_dashboard_pages_path(project))
    expect(Grids::DashboardPage.active_in(project)).to include(standard)
  end

  it "enables an available standard dashboard and disables it only for the current project" do
    standard.dashboard_page_assignments.find_by!(project:).destroy!
    settings_path = settings_project_dashboard_pages_path(project, dashboard_type: "standard")
    toggle_path = toggle_standard_project_dashboard_page_path(project, standard, dashboard_type: "standard")
    headers = { "Accept" => Mime[:turbo_stream].to_s }

    get settings_path
    expect(response).to have_http_status(:ok)
    switch = response.parsed_body.at_css("[data-test-selector='toggle-standard-dashboard-#{standard.id}']")
    expect(switch).to be_present
    expect(Grids::DashboardPage.active_in(project)).not_to include(standard)

    put(toggle_path, params: { value: "true" }, headers:)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<turbo-stream", "project-dashboard-#{standard.id}")
    get project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:ok)

    put(toggle_path, params: { value: "false" }, headers:)
    expect(response).to have_http_status(:ok)
    get project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:not_found)
    expect(Grids::DashboardPage.active_in(destination)).to include(standard)
    expect(standard.dashboard_page_assignments.where(project:).count).to eq(1)
  end

  it "keeps the standard configuration read-only for a project manager" do
    get project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Save as")
    document = response.parsed_body
    toolbar = document.at_css('[data-test-selector="dashboard-toolbar"]')
    expect(toolbar.at_css("a[href='#{deactivate_project_dashboard_page_path(project, standard)}']")).to be_present
    expect(toolbar.text).not_to include("Default dashboard", "Edit standard dashboard", "Rename", "Delete")
    expect(document.at_css('[data-test-selector="overview-tabs"] action-menu')).to be_nil

    get "/api/v3/grids/#{standard.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to have_json_path("_links/updateImmediately")

    patch project_dashboard_page_path(project, standard), params: { dashboard_page: { name: "Changed" } }
    expect(response).to have_http_status(:not_found)
    expect(standard.reload.name).to eq("Progress Report")
  end

  it "renames and deletes a local dashboard from its toolbar" do
    dashboard = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1)
    rename_path = rename_dialog_project_dashboard_page_path(project, dashboard)
    delete_path = deletion_dialog_project_dashboard_page_path(project, dashboard)
    headers = { "Accept" => Mime[:turbo_stream].to_s }

    get project_dashboard_page_path(project, dashboard)
    toolbar = response.parsed_body.at_css('[data-test-selector="dashboard-toolbar"]')
    expect(toolbar.at_css("a[href='#{rename_path}']")).to be_present
    expect(toolbar.at_css("a[href='#{delete_path}']")).to be_present

    get(rename_path, headers:)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rename-dashboard-dialog", 'value="Delivery"')

    patch project_dashboard_page_path(project, dashboard), params: { dashboard_page: { name: "Updated" } }
    expect(response).to redirect_to(project_dashboard_page_path(project, dashboard))
    expect(dashboard.reload.name).to eq("Updated")

    get(delete_path, headers:)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Deleting this dashboard removes it from this project.")

    delete project_dashboard_page_path(project, dashboard)
    expect(response).to redirect_to(project_overview_path(project))
    expect(Grids::DashboardPage.exists?(dashboard.id)).to be(false)
  end

  it "renames and deletes an inactive project dashboard from the settings list" do
    dashboard = Grids::DashboardPage.create!(project:, name: "Delivery", row_count: 1, column_count: 1, disabled: true)
    origin = { from_settings: "1" }
    settings_path = settings_project_dashboard_pages_path(project)
    rename_path = rename_dialog_project_dashboard_page_path(project, dashboard, **origin)
    delete_path = deletion_dialog_project_dashboard_page_path(project, dashboard, **origin)

    get settings_path
    row = response.parsed_body.at_css("[data-dashboard-tab-key='#{dashboard.id}']")
    expect(row.at_css("a[href='#{rename_path}'][data-controller='async-dialog']")).to be_present
    expect(row.at_css("a[href='#{delete_path}'][data-controller='async-dialog']")).to be_present

    action = project_dashboard_page_path(project, dashboard, **origin)
    patch action, params: { dashboard_page: { name: "Updated" } }
    expect(response).to redirect_to(settings_path)
    expect(dashboard.reload.name).to eq("Updated")

    delete action
    expect(response).to redirect_to(settings_path)
    expect(Grids::DashboardPage.exists?(dashboard.id)).to be(false)
  end

  it "renames the original project dashboard from its toolbar" do
    dashboard = create(:overview, project:)
    rename_dialog_path = project_rename_original_dashboard_dialog_path(project)
    rename_path = project_rename_original_dashboard_path(project)

    get dashboard_project_overview_path(project)
    toolbar = response.parsed_body.at_css('[data-test-selector="dashboard-toolbar"]')
    expect(toolbar.at_css("a[href='#{rename_dialog_path}']")).to be_present
    expect(toolbar.at_css('[data-test-selector="overview--add-widgets-button"]')).to be_present

    get rename_dialog_path, headers: { "Accept" => Mime[:turbo_stream].to_s }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("rename-dashboard-dialog", 'value="Dashboard"')

    patch rename_path, params: { dashboard_page: { name: "Project report" } }
    expect(response).to redirect_to(dashboard_project_overview_path(project))
    expect(dashboard.reload.name).to eq("Project report")

    follow_redirect!
    expect(response.parsed_body.at_css('[data-test-selector="project-dashboard-tab"]').text).to include("Project report")
  end

  it "protects standard dashboards from deletion through project routes" do
    delete project_dashboard_page_path(project, standard)

    expect(response).to have_http_status(:not_found)
    expect(standard.reload).to be_persisted
  end

  it "copies a dashboard and its widgets into a permitted target" do
    path = save_as_project_dashboard_page_path(project, standard)
    get project_dashboard_page_path(project, standard)
    toolbar = response.parsed_body.at_css('[data-test-selector="dashboard-toolbar"]')
    expect(toolbar.at_css("a[href='#{path}'][data-controller='async-dialog']")).to be_present

    get path, headers: { "Accept" => Mime[:turbo_stream].to_s }
    expect(response).to have_http_status(:ok)
    dialog = Nokogiri::HTML.fragment(response.body).at_css("#save-dashboard-as-dialog")
    options = dialog.css("select[name='dashboard_page[project_id]'] option")
    expect(options.pluck("value")).to contain_exactly(project.id.to_s, destination.id.to_s)
    expect(options.map(&:text)).to contain_exactly(project.name, destination.name)
    expect(dialog.at_css("option[selected]")["value"]).to eq(project.id.to_s)

    post copy_project_dashboard_page_path(project, standard),
         params: { dashboard_page: { project_id: destination.id, name: "Local report" } }

    copy = Grids::DashboardPage.find_by!(project: destination, name: "Local report")
    expect(response).to redirect_to(project_dashboard_page_path(destination, copy))
    expect(copy.widgets.sole.options).to eq(standard.widgets.sole.options)
    expect(copy.widgets.sole.id).not_to eq(standard.widgets.sole.id)
  end

  it "keeps the original dashboard's Save as dialog open when the name is invalid" do
    original = create(:overview, project:)
    headers = { "Accept" => Mime[:turbo_stream].to_s }
    copy_path = project_copy_original_dashboard_path(project)

    get(project_save_as_original_dashboard_path(project), headers:)
    expect(response).to have_http_status(:ok)
    dialog = Nokogiri::HTML.fragment(response.body).at_css("#save-dashboard-as-dialog")
    expect(dialog.at_css("form")["action"]).to eq(copy_path)
    expect(dialog.at_css("input[name='dashboard_page[name]']")["value"]).to eq(original.display_name)

    post(copy_path, params: { dashboard_page: { project_id: destination.id, name: "" } }, headers:)
    expect(response).to have_http_status(:unprocessable_entity)
    dialog = Nokogiri::HTML.fragment(response.body).at_css("#save-dashboard-as-dialog")
    expect(dialog.at_css("option[selected]")["value"]).to eq(destination.id.to_s)
    expect(dialog.text).to include("can't be blank")
  end

  context "without dashboard management rights" do
    let(:user) { create(:user, member_with_permissions: { project => [] }) }

    it "shows the standard dashboard without an actions toolbar" do
      get project_dashboard_page_path(project, standard)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.at_css('[data-test-selector="dashboard-toolbar"]')).to be_nil
      settings_path = settings_project_dashboard_pages_path(project)
      expect(response.parsed_body.at_css("a[href='#{settings_path}']")).to be_nil

      put project_move_dashboard_tab_path(project, standard.id),
          params: { list_type: Overviews::DashboardTabs::SORTABLE_LIST_TYPE, prev_id: "" }
      expect(response).to have_http_status(:forbidden)

      put toggle_standard_project_dashboard_page_path(project, standard), params: { value: "false" }
      expect(response).to have_http_status(:forbidden)
      expect(Grids::DashboardPage.active_in(project)).to include(standard)

      create(:overview, project:)
      patch project_rename_original_dashboard_path(project), params: { dashboard_page: { name: "Changed" } }
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "with global dashboard management rights only" do
    let(:user) do
      create(:user, global_permissions: [:manage_standard_dashboards], member_with_permissions: { project => [] })
    end

    it "offers a link to administration and keeps the dashboard read-only in the project" do
      get project_dashboard_page_path(project, standard)

      document = response.parsed_body
      toolbar = document.at_css('[data-test-selector="dashboard-toolbar"]')
      expect(toolbar.at_css("a[href='#{edit_admin_dashboard_page_path(standard)}']").text.strip)
        .to eq("Edit standard dashboard in administration")
      expect(toolbar.text).not_to include("Rename", "Delete", "Deactivate dashboard", "Edit dashboard in project settings")
      expect(toolbar.at_css('[data-test-selector="overview--add-widgets-button"]')).to be_nil
      expect(document.at_css("opce-dashboard")["data-read-only"]).to eq("true")
    end

    it "does not allow opening the project dashboard settings list" do
      get settings_project_dashboard_pages_path(project)
      expect(response).to have_http_status(:forbidden)
    end
  end

  it "rejects a forged destination" do
    expect do
      post copy_project_dashboard_page_path(project, standard),
           params: { dashboard_page: { project_id: restricted.id, name: "Local report" } }
    end.not_to change(Grids::DashboardPage, :count)

    expect(response).to have_http_status(:not_found)
  end
end
