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

RSpec.describe "Resource work package timeline view", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }

  before { login_as user }

  it "creates a timeline view and renders its container on show" do
    post project_resource_planner_views_path(project, planner),
         params: { view_class_name: "ResourceWorkPackageTimeline",
                   view: { name: "Epic Planning", filter_mode: "automatic" },
                   filters: [{ status_id: { operator: "o", values: [] } }].to_json },
         as: :turbo_stream
    expect(response).to have_http_status(:ok)

    view = ResourceWorkPackageTimeline.last
    expect(view.name).to eq("Epic Planning")

    get project_resource_planner_view_path(project, planner, view)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("resource-work-package-timeline")
  end
end
