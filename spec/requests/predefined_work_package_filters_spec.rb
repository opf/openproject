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
  let!(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
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
    expect(selector.css("option[selected]").map(&:text)).to eq(["Project overview"])
    expect(document.at_css('input[name="query_props"]')).to be_nil
    expect(document.css("a").map { |link| link.text.strip }).to include("Settings")
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
    expect(document.at_css('button[type="submit"][disabled]').text.strip).to eq("Save")
    expect(document.at_css('button[data-action="admin--predefined-filter-query#edit"]').text.strip).to eq("Edit query")
    summary = document.at_css("#predefined-filter-query-summary")
    expect(summary.text).to include("Columns", "Subject", "Filters", "Ready for delivery",
                                    "Sorting", "Descending", "Group by")
    expect(summary.text).not_to include("Relation type")
  end

  it "previews filter conditions without saving the filter" do
    login_as(admin)
    status = create(:status, name: "Ready for delivery")
    original_properties = filter.query_properties

    post query_summary_admin_predefined_work_package_filters_path,
         params: { query_props: { f: [{ n: "status", o: "=", v: [status.id.to_s] }] }.to_json },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('target="predefined-filter-query-summary"', "Ready for delivery")
    expect(filter.reload.query_properties).to eq(original_properties)
  end

  it "lets project editors update activation for their project" do
    editor = create(:user, member_with_permissions: { project => %i[view_project edit_project] })
    login_as(editor)

    get project_settings_work_packages_filters_path(project)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("filters[#{filter.id}]")

    patch project_settings_work_packages_filters_path(project), params: { filters: { filter.id => "1" } }
    expect(response).to have_http_status(:see_other)
    expect(filter).to be_active_in(project)
    expect(filter).not_to be_active_in(other_project)
  end

  it "rejects global and project writes from a user without the required permissions" do
    login_as(create(:user))

    patch admin_predefined_work_package_filter_path(filter)
    expect(response).to have_http_status(:forbidden)

    post query_summary_admin_predefined_work_package_filters_path, params: { query_props: { f: [] }.to_json }
    expect(response).to have_http_status(:forbidden)

    patch configuration_admin_predefined_work_package_filter_path(filter), params: { query_props: { f: [] }.to_json }
    expect(response).to have_http_status(:forbidden)

    delete project_admin_predefined_work_package_filter_path(filter, project)
    expect(response).to have_http_status(:forbidden)

    patch project_settings_work_packages_filters_path(project), params: { filters: { filter.id => "1" } }
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
