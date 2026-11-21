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

RSpec.describe "Standard dashboard administration", :skip_csrf, type: :rails_request do
  let!(:project) { create(:project, public: false) }
  let(:user) { create(:user, global_permissions: [:manage_standard_dashboards]) }

  current_user { user }

  it "lets a global dashboard manager create a template and open its settings" do
    get admin_index_path
    expect(response).to redirect_to(admin_dashboard_pages_path)

    get admin_dashboard_pages_path
    expect(response).to have_http_status(:ok)
    get new_admin_dashboard_page_path
    expect(response).to have_http_status(:ok)

    post admin_dashboard_pages_path, params: { dashboard_page: { name: "Progress Report" } }

    dashboard = Grids::DashboardPage.central.find_by!(name: "Progress Report")
    expect(response).to redirect_to(edit_admin_dashboard_page_path(dashboard))
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("opce-dashboard")
    document = response.parsed_body
    expect(document.at_css("a[href='#{projects_admin_dashboard_page_path(dashboard)}']").text.strip).to eq("Projects")
    expect(document.at_css("select[multiple]")).to be_nil
    expect(document.at_css("#op-header-project-frame")["src"]).not_to include("jump=")
  end

  it "lets a global dashboard manager update the widget layout" do
    dashboard = Grids::DashboardPage.create!(name: "Progress Report", row_count: 1, column_count: 1)
    get "/api/v3/grids/#{dashboard.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).to have_json_path("_links/updateImmediately")

    token = create(:api_token, user:)
    patch "/api/v3/grids/#{dashboard.id}",
          params: {
            rowCount: 2,
            widgets: [{ identifier: "project_description", startRow: 1, endRow: 2, startColumn: 1, endColumn: 2 }]
          },
          headers: { "Authorization" => "Bearer #{token.plain_value}" },
          as: :json
    expect(response).to have_http_status(:ok)
    expect(dashboard.reload.widgets.sole.identifier).to eq("project_description")
  end

  it "preserves a project's deactivation when saving global changes" do
    dashboard = Grids::DashboardPage.create!(name: "Progress Report", row_count: 1, column_count: 1)
    assignment = dashboard.dashboard_page_assignments.create!(project:, active: false)

    patch admin_dashboard_page_path(dashboard),
          params: { dashboard_page: { name: "Updated" } }

    expect(response).to redirect_to(edit_admin_dashboard_page_path(dashboard))
    expect(assignment.reload).not_to be_active
    expect(dashboard.reload.name).to eq("Updated")
  end

  it "adds and removes project assignments in the Projects tab" do
    dashboard = Grids::DashboardPage.create!(name: "Progress Report", row_count: 1, column_count: 1)
    path = projects_admin_dashboard_page_path(dashboard)

    get path
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.at_css("#standard-dashboard-add-projects-dialog")).to be_present

    post path, params: { project_ids: [{ nodeId: project.id }.to_json] }
    expect(response).to redirect_to(path)
    expect(Grids::DashboardPage.active_in(project)).to include(dashboard)

    follow_redirect!
    expect(response.parsed_body.at_css('[role="table"]').text).to include(project.name)

    delete project_admin_dashboard_page_path(dashboard, project)
    expect(response).to redirect_to(path)
    expect(Grids::DashboardPage.in_project(project)).not_to include(dashboard)
  end

  context "when the user has only the project permission" do
    let(:user) { create(:user, member_with_permissions: { project => %i[manage_dashboards] }) }

    it "denies dashboard administration" do
      get admin_dashboard_pages_path
      expect(response).to have_http_status(:forbidden)
    end
  end
end
