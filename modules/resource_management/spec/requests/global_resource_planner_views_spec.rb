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

RSpec.describe "Global resource planner views requests",
               :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:alpha) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:beta) { create(:project, name: "Beta", enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:invisible) do
    create(:project, name: "Invisible", enabled_module_names: %w[resource_management work_package_tracking])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: { alpha => %i[view_resource_planners view_work_packages],
                                      beta => %i[view_resource_planners view_work_packages] },
           global_permissions: %i[view_global_resource_planners])
  end

  shared_let(:planner) { create(:resource_planner, :global, principal: user, name: "Capacity") }

  shared_let(:alpha_wp) { create(:work_package, project: alpha, subject: "Alpha work") }
  shared_let(:beta_wp) { create(:work_package, project: beta, subject: "Beta work") }
  shared_let(:invisible_wp) { create(:work_package, project: invisible, subject: "Secret work") }

  before { login_as(user) }

  describe "creating a view" do
    it "creates a work package list on a global planner and redirects to it" do
      expect do
        post resource_planner_views_path(planner),
             params: { view_class_name: "ResourceWorkPackageList",
                       view: { name: "All work", filter_mode: "manual" } },
             as: :turbo_stream
      end.to change(ResourceWorkPackageList, :count).by(1)

      view = ResourceWorkPackageList.last
      expect(view.parent).to eq(planner)
      expect(view.project).to be_nil
      expect(response.body).to include(resource_planner_view_path(planner, view))
    end
  end

  describe "with an existing view" do
    shared_let(:view) do
      ResourceWorkPackageList.create!(name: "All work", parent: planner, project: nil, principal: user,
                                      query: Query.new_default(project: nil, user:).tap { |q| q.update!(name: "q") })
    end

    it "renders the view with the global sidebar menu" do
      get resource_planner_view_path(planner, view)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("resource_planners_sidemenu")
      expect(response.body).to include(menu_resource_planners_path)
    end

    it "names each work package's project, which the planner spans several of" do
      post work_packages_resource_planner_view_path(planner, view),
           params: { work_package_id: beta_wp.id },
           as: :turbo_stream

      get resource_planner_view_path(planner, view)

      expect(response.body).to include(project_overview_path(beta))
    end

    it "accepts a work package from any project the user can see" do
      post work_packages_resource_planner_view_path(planner, view),
           params: { work_package_id: beta_wp.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(view.reload.work_packages).to include(beta_wp)
    end

    it "rejects a work package from a project the user cannot see" do
      post work_packages_resource_planner_view_path(planner, view),
           params: { work_package_id: invisible_wp.id },
           as: :turbo_stream

      expect(response).to have_http_status(:bad_request)
      expect(view.reload.work_packages).not_to include(invisible_wp)
    end
  end

  describe "with a timeline view" do
    shared_let(:view) do
      ResourceWorkPackageTimeline.create!(name: "Timeline", parent: planner, project: nil, principal: user,
                                          query: Query.new_default(project: nil, user:)
                                                      .tap { |q| q.update!(name: "q") })
    end

    it "renders and points its feeds at the global endpoints" do
      get resource_planner_view_path(planner, view)

      expect(response).to have_http_status(:ok)
      expect(response.body)
        .to include(resource_planner_view_work_package_timeline_resources_path(planner, view, format: :json))
      expect(response.body)
        .to include(resource_planner_view_work_package_timeline_events_path(planner, view, format: :json))
    end
  end

  describe "with a user card view" do
    shared_let(:view) do
      ResourceUserCard.create!(name: "Team", parent: planner, project: nil, principal: user,
                               query: UserQuery.new(name: "q", project: nil, principal: user).tap(&:save!))
    end

    shared_let(:beta_member) do
      create(:user, firstname: "Beta", lastname: "Member", member_with_permissions: { beta => %i[view_work_packages] })
    end

    it "accepts a member of any project the user can see" do
      post users_resource_planner_view_path(planner, view),
           params: { user_id: beta_member.id },
           as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(view.reload.results).to include(beta_member)
    end
  end

  context "without the global permission" do
    shared_let(:project_only_user) do
      create(:user, member_with_permissions: { alpha => %i[view_resource_planners] })
    end

    before { login_as(project_only_user) }

    it "cannot reach a global planner's view" do
      view = ResourceWorkPackageList.create!(name: "All work", parent: planner, project: nil, principal: user)

      get resource_planner_view_path(planner, view)

      expect(response).to have_http_status(:not_found)
    end
  end
end
