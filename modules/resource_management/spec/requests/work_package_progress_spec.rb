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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "WorkPackage progress requests", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_resource_planners view_work_packages edit_work_packages]
           })
  end
  shared_let(:resource_planner) { create(:resource_planner, project:, principal: user, public: true) }
  shared_let(:view) do
    create(:resource_work_package_list, name: "Team work", parent: resource_planner, project:, principal: user)
  end
  shared_let(:work_package) { create(:work_package, project:, subject: "Build the thing") }

  let(:edit_path) do
    edit_project_resource_planner_view_work_package_progress_path(project, resource_planner, view, work_package)
  end
  let(:update_path) do
    project_resource_planner_view_work_package_progress_path(project, resource_planner, view, work_package)
  end
  let(:preview_path) do
    preview_project_resource_planner_view_work_package_progress_path(project, resource_planner, view, work_package)
  end

  before { login_as(user) }

  describe "GET edit" do
    it "renders the progress modal inside the edit dialog" do
      get edit_path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ResourcePlannerViews::WorkPackageList::EditTotalWorkDialogComponent::DIALOG_ID)
      expect(response.body).to include("work_package_progress_modal")
      # The form posts back here, not to the core progress controller.
      expect(response.body).to include(update_path)
    end
  end

  describe "PATCH update" do
    let(:params) do
      {
        "work_package" => {
          "estimated_hours" => "42",
          "remaining_hours" => "4h",
          "done_ratio" => "90",
          "estimated_hours_touched" => "true",
          "remaining_hours_touched" => "true",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "applies the touched values, closes the dialog and refreshes the list" do
      patch update_path, params:, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      work_package.reload
      expect(work_package.estimated_hours).to eq(42)
      expect(work_package.remaining_hours).to eq(4)

      # The work package list content is re-rendered inline (its sub-header
      # links back to the view's settings) and a success flash is shown.
      expect(response.body).to include(edit_project_resource_planner_view_path(project, resource_planner, view))
      expect(response).to have_turbo_stream action: "flash"
    end

    context "when a progress value is invalid" do
      before { params["work_package"]["estimated_hours"] = "-1" }

      it "replies 422 and re-renders the modal without persisting" do
        patch update_path, params:, as: :turbo_stream

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to have_turbo_stream action: "update"
        expect(work_package.reload.estimated_hours).to be_nil
      end
    end
  end

  describe "GET preview" do
    let(:params) do
      {
        "field" => "work_package[estimated_hours]",
        "work_package" => {
          "estimated_hours" => "10",
          "remaining_hours" => "",
          "done_ratio" => "",
          "estimated_hours_touched" => "true",
          "remaining_hours_touched" => "false",
          "done_ratio_touched" => "false"
        }
      }
    end

    it "renders the progress modal frame with derived values without persisting" do
      get preview_path, params:, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("work_package_progress_modal")
      expect(work_package.reload.estimated_hours).to be_nil
    end
  end

  describe "authorization" do
    context "without the edit_work_packages permission" do
      shared_let(:viewer) do
        create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
      end

      before { login_as(viewer) }

      it "is forbidden" do
        get edit_path, as: :turbo_stream

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the work package is not visible to the user" do
      let(:other_project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
      let(:invisible_work_package) { create(:work_package, project: other_project) }
      let(:invisible_path) do
        edit_project_resource_planner_view_work_package_progress_path(
          project, resource_planner, view, invisible_work_package
        )
      end

      it "returns not found" do
        get invisible_path, as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
