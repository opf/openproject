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

RSpec.describe "Predefined work package filters", :skip_csrf, type: :rails_request do
  let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking calendar_view gantt]) }
  let(:other_project) { create(:project) }
  let(:admin) { create(:admin) }
  let!(:filter) do
    PredefinedWorkPackageFilter.create!(name: "Artefacts", placement: :project_overview,
                                        query_properties: { "g" => "status", "f" => [] })
  end

  it "gives administrators access to the list and project selection", :aggregate_failures do
    login_as(admin)
    create(:status)
    filter.update!(query_properties: { "f" => [{ "n" => "status", "o" => "o", "v" => [] }] })

    get admin_predefined_work_package_filters_path
    expect(response).to have_http_status(:ok)
    row = response.parsed_body.at_css("#predefined_work_package_filter_#{filter.id}")
    expect(row.text).to include("Artefacts", "Status open (to-do + in progress)")

    get projects_admin_predefined_work_package_filter_path(filter)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("#predefined-filter-add-projects-dialog")).to be_present
  end

  it "lets a filter manager add and remove projects through the Projects tab", :aggregate_failures do
    role = create(:global_role, permissions: [:manage_filters])
    login_as(create(:user, global_roles: [role]))
    path = projects_admin_predefined_work_package_filter_path(filter)

    post path, params: { project_ids: [{ nodeId: project.id }.to_json] }
    expect(response).to redirect_to(path)
    expect(filter).to be_active_in(project)
    expect(filter).not_to be_active_in(other_project)

    get path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css('[role="table"]').text).to include(project.name)

    delete project_admin_predefined_work_package_filter_path(filter, project)
    expect(response).to redirect_to(path)
    expect(filter).not_to be_active_in(project)
  end

  it "lets a non-administrator with Manage filters configure and reorder filters" do
    role = create(:global_role, permissions: [:manage_filters])
    login_as(create(:user, global_roles: [role]))

    get admin_index_path
    expect(response).to redirect_to(admin_predefined_work_package_filters_path)

    get new_admin_predefined_work_package_filter_path
    expect(response).to have_http_status(:ok)

    expect(response.parsed_body.at_css('input[name="query_props"]')).to be_nil

    post admin_predefined_work_package_filters_path,
         params: { predefined_work_package_filter: { name: "Delivery", placement: "gantt" } }
    expect(response).to have_http_status(:see_other)
    created = PredefinedWorkPackageFilter.find_by!(name: "Delivery")
    expect(response).to redirect_to(configuration_admin_predefined_work_package_filter_path(created))
    expect(created).not_to be_active_in(project)

    put move_admin_predefined_work_package_filter_path(created),
        params: { list_type: "predefined-work-package-filter", prev_id: "" },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    expect(response).to have_http_status(:ok)
    expect(created.reload.position).to be < filter.reload.position

    delete admin_predefined_work_package_filter_path(created)
    expect(response).to have_http_status(:see_other)
    expect(PredefinedWorkPackageFilter.exists?(created.id)).to be false
  end

  it "shows a single display selector in Settings separately from the query configuration", :aggregate_failures do
    login_as(admin)

    get edit_admin_predefined_work_package_filter_path(filter)

    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    selector = document.at_css('select[name="predefined_work_package_filter[placement]"]')
    expect(selector["multiple"]).to be_nil
    expect(selector.at_css('option[value="calendar"]').text).to eq(I18n.t(:label_calendar))
    expect(selector.css("option[selected]").map(&:text)).to eq([PredefinedWorkPackageFilter.placement_label(filter.placement)])
    expect(document.at_css('input[name="query_props"]')).to be_nil
    expect(document.at_css('button[type="submit"]').text.strip).to eq(I18n.t(:button_save))
    expect(document.css("a").map { |link| link.text.strip }).to include(I18n.t(:label_setting_plural))
  end

  it "combines display and case-insensitive name filters in the list", :aggregate_failures do
    login_as(admin)
    calendar_filter = PredefinedWorkPackageFilter.create!(name: "Upcoming milestones", placement: :calendar)
    gantt_filter = PredefinedWorkPackageFilter.create!(name: "Plan milestones", placement: :gantt)
    other_calendar_filter = PredefinedWorkPackageFilter.create!(name: "Release dates", placement: :calendar)

    get admin_predefined_work_package_filters_path, params: {
      filters: [
        { placement: { operator: "=", values: ["calendar"] } },
        { name: { operator: "~", values: ["MILESTONES"] } }
      ].to_json
    }

    expect(response).to have_http_status(:ok)
    table = response.parsed_body.at_css("turbo-frame#predefined-work-package-filter-list #predefined-work-package-filters-table")
    expect(table.at_css("#predefined_work_package_filter_#{calendar_filter.id}")).to be_present
    expect(table.at_css("#predefined_work_package_filter_#{gantt_filter.id}")).to be_nil
    expect(table.at_css("#predefined_work_package_filter_#{other_calendar_filter.id}")).to be_nil
    expect(table["data-controller"]).to be_nil
  end

  it "finds a built-in filter by its displayed name", :aggregate_failures do
    login_as(admin)
    builtin = PredefinedWorkPackageFilter.find_by!(builtin_key: "assigned_to_me")

    get admin_predefined_work_package_filters_path,
        params: { filters: [{ name: { operator: "~", values: [builtin.display_name.downcase] } }].to_json }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("#predefined_work_package_filter_#{builtin.id}")).to be_present
  end

  it "opens a project calendar with the configured filter only after activation", :aggregate_failures do
    login_as(admin)
    status_filters = [{ "n" => "status", "o" => "o", "v" => [] }]
    filter.update!(query_properties: { "f" => status_filters })

    patch admin_predefined_work_package_filter_path(filter),
          params: { predefined_work_package_filter: { placement: "calendar" } }
    expect(response).to have_http_status(:see_other)
    expect(filter.reload.placement).to eq("calendar")

    get menu_project_calendars_path(project)
    expect(response.body).not_to include(filter.display_name)
    filter.set_active_in!(project, active: true)

    get menu_project_calendars_path(project, name: "predefined_filter_#{filter.id}")
    expect(response).to have_http_status(:ok)
    link = response.parsed_body.css("a").find { |anchor| anchor.text.strip == filter.display_name }
    url = URI.parse(link["href"])
    expect(url.path).to eq(new_project_calendar_path(project))
    expect(JSON.parse(Rack::Utils.parse_query(url.query).fetch("query_props")).fetch("f")).to eq(status_filters)
    get link["href"]
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("opce-calendar-view")
  end

  it "rejects invalid placement values" do
    login_as(admin)

    patch admin_predefined_work_package_filter_path(filter),
          params: { predefined_work_package_filter: { placement: "unknown" } }

    expect(response).to have_http_status(:unprocessable_entity)
    expect(filter.reload.placement).to eq("project_overview")
  end

  it "lets a non-administrator with Manage filters save and view a complete query configuration", :aggregate_failures do
    role = create(:global_role, permissions: [:manage_filters])
    login_as(create(:user, global_roles: [role]))
    status = create(:status, name: "Ready for delivery")
    path = configuration_admin_predefined_work_package_filter_path(filter)
    properties = { g: "status", c: %w[id subject status], t: "subject:desc,id:asc",
                   f: [{ n: "status", o: "=", v: [status.id.to_s] }] }

    patch path, params: { query_props: properties.to_json }
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(path)

    get path
    expect(response).to have_http_status(:ok)
    document = response.parsed_body
    expect(document.at_css('form[data-controller="admin--predefined-filter-query"] button[type="submit"]')).to be_nil
    edit_button = document.at_css('button[data-action="admin--predefined-filter-query#edit"]')
    expect(edit_button.text.strip).to eq(I18n.t("types.edit.form_configuration.edit_query"))
    summary = document.at_css("#predefined-filter-query-summary")
    expect(summary.text).to include("Columns", "Subject", "Filters", "Ready for delivery",
                                    "Sorting", "Descending", "Group by")
    expect(summary.text).not_to include("Relation type")
  end

  {
    work_packages: [:project_work_packages_path, "opce-work-packages-view"],
    gantt: [:project_gantt_index_path, "opce-work-packages-view"],
    calendar: [:new_project_calendar_path, "opce-calendar-view"]
  }.each do |placement, (route, component)|
    it "offers the active #{placement} filter configuration only to filter managers", :aggregate_failures do
      filter.update!(placement:)
      settings_path = configuration_admin_predefined_work_package_filter_path(filter)
      view_path = public_send(route, project, **WorkPackages::PredefinedFilterQuery.new(filter, project:).menu_params(placement))
      permissions = %i[view_project view_work_packages view_calendar]
      member = create(:user, member_with_permissions: { project => permissions })
      role = create(:global_role, permissions: [:manage_filters])
      manager = create(:user, global_roles: [role], member_with_permissions: { project => permissions })

      login_as(manager)
      get view_path
      expect(response.parsed_body.at_css(component)["data-predefined-filter-configuration-path"]).to be_nil

      filter.set_active_in!(project, active: true)
      get view_path
      entry = response.parsed_body.at_css(component)
      expect(entry["data-predefined-filter-title"]).to eq(filter.display_name)
      expect(entry["data-predefined-filter-configuration-path"]).to eq(settings_path)

      login_as(member)
      get view_path
      entry = response.parsed_body.at_css(component)
      expect(entry["data-predefined-filter-title"]).to eq(filter.display_name)
      expect(entry["data-predefined-filter-configuration-path"]).to be_nil
    end
  end

  it "offers the overview filter configuration even when the filter has no results" do
    filter.set_active_in!(project, active: true)
    path = project_overview_path(project, predefined_filter_id: filter.id)
    settings_path = configuration_admin_predefined_work_package_filter_path(filter)
    selector = "a[href='#{settings_path}']"

    login_as(admin)
    get path
    expect(response.parsed_body.at_css(selector).text.strip).to eq(I18n.t("js.toolbar.settings.configure_filter"))

    login_as(create(:user, member_with_permissions: { project => %i[view_project view_work_packages] }))
    get path
    expect(response.parsed_body.at_css(selector)).to be_nil
  end

  it "lets project editors switch an individual filter on and off immediately" do
    login_as(create(:user, member_with_permissions: { project => %i[view_project edit_project] }))
    toggle_path = toggle_project_settings_work_packages_filters_path(project, filter)

    get project_settings_work_packages_filters_path(project)
    expect(response).to have_http_status(:ok)
    row = response.parsed_body.at_css("#predefined_work_package_filter_#{filter.id}")
    expect(row.text).to include("Artefacts", "Project overview")
    expect(row.at_css("toggle-switch")["src"]).to eq(toggle_path)
    expect(row.at_css("button")["aria-pressed"]).to eq("false")

    post toggle_path, params: { value: "1" }
    expect(response).to have_http_status(:ok)
    expect(filter).to be_active_in(project)
    expect(filter).not_to be_active_in(other_project)

    post toggle_path, params: { value: "0" }
    expect(response).to have_http_status(:ok)
    expect(filter).not_to be_active_in(project)
  end

  it "filters the project activation table by display name" do
    login_as(admin)
    PredefinedWorkPackageFilter.create!(name: "Milestones", placement: :gantt)
    filters = [{ name: { operator: "~", values: ["ARTE"] } }].to_json

    get project_settings_work_packages_filters_path(project, filters:), headers: { "Turbo-Frame" => "project-filter-list" }

    expect(response).to have_http_status(:ok)
    frame = response.parsed_body.at_css("turbo-frame#project-filter-list")
    expect(frame.at_css("#project-filters-name-search")["value"]).to eq("ARTE")
    expect(frame.css("[role='rowheader']").map { |cell| cell.text.strip }).to eq(["Artefacts"])
  end

  it "rejects global and project writes from a user without the required permissions" do
    login_as(create(:user))

    patch admin_predefined_work_package_filter_path(filter)
    expect(response).to have_http_status(:forbidden)

    patch configuration_admin_predefined_work_package_filter_path(filter), params: { query_props: { f: [] }.to_json }
    expect(response).to have_http_status(:forbidden)

    delete project_admin_predefined_work_package_filter_path(filter, project)
    expect(response).to have_http_status(:forbidden)

    patch project_settings_work_packages_filters_path(project), params: { filters: { filter.id => "1" } }
    expect(response).to have_http_status(:not_found)

    post toggle_project_settings_work_packages_filters_path(project, filter), params: { value: "1" }
    expect(response).to have_http_status(:not_found)
    expect(filter).not_to be_active_in(project)
  end

  it "groups matching project work packages into one box per phase" do
    login_as(admin)
    initiating = create(:project_phase, project:, definition: create(:project_phase_definition, name: "Initiating"))
    executing = create(:project_phase, project:, definition: create(:project_phase_definition, name: "Executing"))
    create(:work_package, project:, project_phase_definition: initiating.definition, subject: "Initial artefact")
    create(:work_package, project:, project_phase_definition: executing.definition, subject: "Execution artefact")
    filter.update!(query_properties: { "g" => "projectPhase", "f" => [] })
    create(:work_package, project: other_project, subject: "Other project artefact")

    get project_overview_path(project, predefined_filter_id: filter.id)
    expect(response).to have_http_status(:not_found)

    filter.set_active_in!(project, active: true)
    get project_overview_path(project, predefined_filter_id: filter.id)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Artefacts")
    document = response.parsed_body
    first_box = document.at_css("##{ActionView::RecordIdentifier.dom_id(project)}_predefined_filter_0")
    second_box = document.at_css("##{ActionView::RecordIdentifier.dom_id(project)}_predefined_filter_1")
    expect(first_box.text).to include("Initiating", "Initial artefact")
    expect(second_box.text).to include("Executing", "Execution artefact")
    expect(response.body).not_to include("Other project artefact")
  end
end
