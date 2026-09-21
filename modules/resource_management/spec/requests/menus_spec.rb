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

RSpec.describe "Global resource planner menu requests", type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management]) }
  shared_let(:invisible) { create(:project, name: "Invisible", enabled_module_names: %w[resource_management]) }

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners] },
           global_permissions: %i[view_global_resource_planners])
  end

  shared_let(:global_planner) { create(:resource_planner, :global, principal: user, name: "Global planner") }
  shared_let(:project_planner) { create(:resource_planner, project:, principal: user, name: "Alpha planner") }
  shared_let(:invisible_planner) do
    create(:resource_planner, project: invisible, principal: create(:user), public: true, name: "Invisible planner")
  end

  before { login_as(user) }

  # The submenu partial is registered on a menu item, so it renders in the view
  # context of whichever controller serves the page. It may therefore only use
  # helpers every view has, not the module's own.
  it "renders the sidebar frame on a global page served by another controller" do
    get projects_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("resource_planners_sidemenu")
  end

  it "renders the global planners" do
    get menu_resource_planners_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Global planner")
  end

  it "does not list project planners" do
    get menu_resource_planners_path

    expect(response.body).not_to include("Alpha planner", "Invisible planner")
  end

  context "without any resource planner permission" do
    before { login_as(create(:user)) }

    it "is forbidden" do
      get menu_resource_planners_path

      expect(response).to have_http_status(:forbidden)
    end
  end
end
