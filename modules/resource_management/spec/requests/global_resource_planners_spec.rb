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

RSpec.describe "Global resource planners requests",
               :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management]) }
  shared_let(:invisible) { create(:project, name: "Invisible", enabled_module_names: %w[resource_management]) }

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners] },
           global_permissions: %i[view_global_resource_planners])
  end

  shared_let(:project_planner) do
    create(:resource_planner, project:, principal: user, name: "Project planner")
  end
  shared_let(:global_planner) do
    create(:resource_planner, :global, principal: user, name: "Global planner")
  end
  shared_let(:invisible_planner) do
    create(:resource_planner, project: invisible, principal: create(:user), public: true, name: "Invisible planner")
  end

  before { login_as(user) }

  it "renders the global index with the global sidebar menu" do
    get resource_planners_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("resource_planners_sidemenu")
    expect(response.body).to include(menu_resource_planners_path)
  end

  it "lists only global planners, linking them into the global scope" do
    get resource_planners_path

    expect(response.body).to include("Global planner")
    expect(response.body).to include(resource_planner_path(global_planner))
  end

  it "does not list project planners" do
    get resource_planners_path

    expect(response.body).not_to include("Project planner", "Invisible planner")
  end

  it "renders a planner's show page with the global sidebar menu" do
    get resource_planner_path(global_planner)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("resource_planners_sidemenu")
  end

  it "offers a create link into the global scope" do
    get resource_planners_path

    expect(response.body).to include(new_resource_planner_path)
  end

  it "renders the new planner dialog" do
    get new_resource_planner_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
  end

  it "creates a global planner and advances to the configure step" do
    expect do
      post resource_planners_path,
           params: { resource_planner: { name: "Cross-project capacity",
                                         default_view_class_name: "ResourceWorkPackageList" } },
           as: :turbo_stream
    end.to change(ResourcePlanner.where(project: nil), :count).by(1)

    planner = ResourcePlanner.last
    expect(planner).to have_attributes(name: "Cross-project capacity", project: nil, principal: user)
    expect(response.body).to include(resource_planner_views_path(planner))
  end

  context "without the global permission" do
    shared_let(:project_only_user) do
      create(:user, member_with_permissions: { project => %i[view_resource_planners] })
    end

    before { login_as(project_only_user) }

    it "still reaches the section but sees no global planners" do
      get resource_planners_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Global planner")
    end
  end

  context "without any resource planner permission" do
    before { login_as(create(:user)) }

    it "is forbidden" do
      get resource_planners_path

      expect(response).to have_http_status(:forbidden)
    end
  end
end
