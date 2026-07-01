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

RSpec.describe "ResourcePlanners requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end

  let(:resource_planner) { create(:resource_planner, project:, principal: user, name: "Original") }

  before { login_as user }

  describe "GET edit" do
    it "responds with the edit dialog turbo stream" do
      get edit_project_resource_planner_path(project, resource_planner),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ResourcePlanners::EditDialogComponent::DIALOG_ID)
      # The default-view field is excluded in edit mode.
      expect(response.body).not_to include("resource_planner_default_view_class_name")
    end
  end

  describe "PATCH update" do
    it "updates the planner and redirects to the show page" do
      patch project_resource_planner_path(project, resource_planner),
            params: { resource_planner: { name: "Renamed" } }

      expect(response).to redirect_to(project_resource_planner_path(project, resource_planner))
      expect(resource_planner.reload.name).to eq("Renamed")
    end

    it "favorites the planner when the favorite flag is set" do
      patch project_resource_planner_path(project, resource_planner),
            params: { resource_planner: { name: "Original", favorite: "1" } }

      expect(resource_planner.favorited_by?(user)).to be(true)
    end

    it "re-renders the form with errors when invalid" do
      patch project_resource_planner_path(project, resource_planner),
            params: { resource_planner: { name: "" } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(resource_planner.reload.name).to eq("Original")
    end
  end

  describe "DELETE destroy" do
    it "deletes the planner and redirects to the index" do
      resource_planner

      expect do
        delete project_resource_planner_path(project, resource_planner)
      end.to change(ResourcePlanner, :count).by(-1)

      expect(response).to redirect_to(project_resource_planners_path(project))
    end
  end
end
