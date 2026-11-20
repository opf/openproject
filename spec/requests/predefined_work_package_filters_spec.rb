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
    PredefinedWorkPackageFilter.create!(name: "Artefacts", project_overview: true, work_packages: true,
                                        query_properties: { "g" => "status", "f" => [] })
  end

  it "gives administrators access to the list and project selection", :aggregate_failures do
    login_as(admin)

    get admin_predefined_work_package_filters_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Artefacts")

    get projects_admin_predefined_work_package_filter_path(filter)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("projects[#{project.id}]")

    patch projects_admin_predefined_work_package_filter_path(filter), params: { projects: { project.id => "1" } }
    expect(response).to have_http_status(:see_other)
    expect(filter).to be_active_in(project)
    expect(filter).not_to be_active_in(other_project)
  end

  it "lets a non-administrator with Manage filters configure and reorder filters" do
    role = create(:global_role, permissions: [:manage_filters])
    login_as(create(:user, global_roles: [role]))

    get admin_index_path
    expect(response).to redirect_to(admin_predefined_work_package_filters_path)

    get new_admin_predefined_work_package_filter_path
    expect(response).to have_http_status(:ok)

    post admin_predefined_work_package_filters_path,
         params: {
           predefined_work_package_filter: { name: "Delivery", work_packages: "1", gantt: "1", group_by: "status" },
           filters: [{ status_id: { operator: "o", values: [] } }].to_json
         }
    expect(response).to have_http_status(:see_other)
    created = PredefinedWorkPackageFilter.find_by!(name: "Delivery")
    expect(created.query_properties).to include("g" => "status",
                                                "f" => [{ "n" => "status", "o" => "o", "v" => [] }])
    expect(created).not_to be_active_in(project)

    patch move_admin_predefined_work_package_filter_path(created, direction: "up")
    expect(response).to have_http_status(:see_other)
    expect(created.reload.position).to be < filter.reload.position

    delete admin_predefined_work_package_filter_path(created)
    expect(response).to have_http_status(:see_other)
    expect(PredefinedWorkPackageFilter.exists?(created.id)).to be false
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
