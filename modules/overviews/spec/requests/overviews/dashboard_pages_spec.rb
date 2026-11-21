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
    expect(response.body).to include("Delivery", "Progress Report", "Configure dashboard")
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
    expect(response.body).to include("Activate dashboard")

    patch activate_project_dashboard_page_path(project, standard)
    expect(response).to redirect_to(settings_project_dashboard_pages_path(project))
    expect(Grids::DashboardPage.active_in(project)).to include(standard)
  end

  it "keeps the standard configuration read-only for a project manager" do
    get project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Save as")
    expect(response.body).not_to include("Default dashboard", "Configure dashboard")

    get "/api/v3/grids/#{standard.id}"
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to have_json_path("_links/updateImmediately")

    patch project_dashboard_page_path(project, standard), params: { dashboard_page: { name: "Changed" } }
    expect(response).to have_http_status(:not_found)
    expect(standard.reload.name).to eq("Progress Report")
  end

  it "copies a dashboard and its widgets into a permitted target" do
    get save_as_project_dashboard_page_path(project, standard)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(destination.name)
    expect(response.body).not_to include(restricted.name)

    post copy_project_dashboard_page_path(project, standard),
         params: { dashboard_page: { project_id: destination.id, name: "Local report" } }

    copy = Grids::DashboardPage.find_by!(project: destination, name: "Local report")
    expect(response).to redirect_to(project_dashboard_page_path(destination, copy))
    expect(copy.widgets.sole.options).to eq(standard.widgets.sole.options)
    expect(copy.widgets.sole.id).not_to eq(standard.widgets.sole.id)
  end

  it "rejects a forged destination" do
    expect do
      post copy_project_dashboard_page_path(project, standard),
           params: { dashboard_page: { project_id: restricted.id, name: "Local report" } }
    end.not_to change(Grids::DashboardPage, :count)

    expect(response).to have_http_status(:not_found)
  end
end
