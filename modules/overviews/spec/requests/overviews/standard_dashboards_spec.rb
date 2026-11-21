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
  let(:project) { create(:project, public: false) }
  let(:user) { create(:user, global_permissions: [:manage_standard_dashboards]) }

  current_user { user }

  it "lets a global dashboard manager publish a template and edit its widget layout" do
    get admin_index_path
    expect(response).to redirect_to(admin_dashboard_pages_path)

    get admin_dashboard_pages_path
    expect(response).to have_http_status(:ok)
    get new_admin_dashboard_page_path
    expect(response).to have_http_status(:ok)

    post admin_dashboard_pages_path, params: { dashboard_page: { name: "Progress Report", project_ids: [project.id] } }

    dashboard = Grids::DashboardPage.central.find_by!(name: "Progress Report")
    expect(response).to redirect_to(edit_admin_dashboard_page_path(dashboard))
    expect(Grids::DashboardPage.active_in(project)).to include(dashboard)
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("opce-dashboard")

    get "/api/v3/grids/#{dashboard.id}"
    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body).fetch("_links")).to have_key("updateImmediately")

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
          params: { dashboard_page: { name: "Updated", project_ids: [project.id] } }

    expect(response).to redirect_to(edit_admin_dashboard_page_path(dashboard))
    expect(assignment.reload).not_to be_active
    expect(dashboard.reload.name).to eq("Updated")
  end

  context "when the user has only the project permission" do
    let(:user) { create(:user, member_with_permissions: { project => %i[manage_dashboards] }) }

    it "denies dashboard administration" do
      get admin_dashboard_pages_path
      expect(response).to have_http_status(:forbidden)
    end
  end
end
