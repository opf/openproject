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

RSpec.describe "Recurring work package series", :skip_csrf, type: :rails_request do
  shared_let(:default_status) { create(:default_status) }
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_work_packages add_work_packages edit_work_packages add_work_package_notes
                           view_recurring_work_packages manage_recurring_work_packages]
           })
  end
  shared_let(:work_package) do
    create(:work_package, project:, type:, author: user, status: default_status, start_date: Date.new(2026, 10, 5))
  end

  current_user { user }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "GET /work_packages/:id/new_recurrence" do
    it "renders the dialog with the work package start date" do
      get new_recurrence_work_package_path(work_package), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(RecurringWorkPackages::DialogComponent::DIALOG_ID)
      expect(response.body).to include('value="2026-10-05"')
    end
  end

  describe "GET /work_packages/:id/recurrence_preview" do
    it "renders the schedule and the upcoming dates" do
      get recurrence_preview_work_package_path(work_package),
          params: { series: { frequency: "weekly", interval: "2", start_date: "2026-10-05", end_after: "never" } },
          headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Every 2 weeks on Monday", "10/19/2026")
    end
  end

  describe "GET /projects/:project_id/work_packages/menu" do
    it "lists the recurring entry" do
      get menu_project_work_packages_path(project, name: "recurring_work_packages")

      expect(response.body).to include("Recurring", project_recurring_work_packages_path(project))
    end
  end

  describe "POST /projects/:project_id/recurring_work_packages" do
    let(:params) do
      { work_package_id: work_package.id,
        series: { frequency: "weekly", interval: "1", start_date: "2026-10-05", end_after: "never" } }
    end

    it "creates the series with the work package as the first occurrence" do
      post project_recurring_work_packages_path(project), params:, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(RecurringWorkPackages::Occurrence.find_by(work_package:)).to have_attributes(position: 1)
    end

    it "re-renders the form with errors for an invalid interval" do
      params[:series][:interval] = "0"
      post project_recurring_work_packages_path(project), params:, headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Interval must be greater than or equal to 1")
    end
  end

  context "with a series" do
    let!(:series) do
      RecurringWorkPackages::CreateService
        .new(user:, work_package:)
        .call(frequency: "weekly", interval: 1, start_date: Date.new(2026, 10, 5))
        .result
    end

    it "renders the index" do
      get project_recurring_work_packages_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Every week on Monday")
    end

    it "renders the series page with the planned dates" do
      get project_recurring_work_package_path(project, series)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(work_package.subject, "Planned for")
    end

    it "creates the next occurrence on demand" do
      post create_next_project_recurring_work_package_path(project, series)

      expect(response).to redirect_to(project_recurring_work_package_path(project, series))
      expect(series.occurrences.count).to eq(2)
    end

    it "ends the series" do
      post end_series_project_recurring_work_package_path(project, series)

      expect(series.reload).to be_ended
    end
  end

  context "without the manage permission" do
    let(:viewer) do
      create(:user, member_with_permissions: { project => %i[view_work_packages view_recurring_work_packages] })
    end

    current_user { viewer }

    it "forbids the dialog" do
      get new_recurrence_work_package_path(work_package), headers: turbo_headers

      expect(response).to have_http_status(:forbidden)
    end
  end
end
