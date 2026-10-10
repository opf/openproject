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
require "rack/test"

RSpec.describe API::V3::AllocatableWorkPackages::AllocatableWorkPackagesAPI,
               "index",
               content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:allocating_project) do
    create(:project, enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:viewing_project) do
    create(:project, enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:plain_project) { create(:project, enabled_module_names: %w[work_package_tracking]) }

  shared_let(:allocatable) { create(:work_package, project: allocating_project, subject: "Allocatable") }
  shared_let(:view_only) { create(:work_package, project: viewing_project, subject: "View only") }
  shared_let(:unmanaged) { create(:work_package, project: plain_project, subject: "Unmanaged") }

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:returned_ids) { parsed_response["_embedded"]["elements"].pluck("id") }
  let(:send_request) { get api_v3_paths.allocatable_work_packages }

  current_user { user }

  before { send_request }

  context "for a user who may allocate somewhere" do
    let(:user) do
      create(:user,
             member_with_permissions: {
               allocating_project => %i[view_work_packages view_resource_planners allocate_user_resources],
               viewing_project => %i[view_work_packages view_resource_planners],
               plain_project => %i[view_work_packages]
             })
    end

    it "offers only work packages the allocation contract would accept" do
      expect(returned_ids).to contain_exactly(allocatable.id)
    end

    context "when the dialog forwards a planner view's filters" do
      let(:send_request) do
        get api_v3_paths.path_for(:allocatable_work_packages,
                                  filters: [{ subject: { operator: "~", values: ["Allocatable"] } }])
      end

      it "still honours the full work package filter vocabulary" do
        expect(last_response).to have_http_status(:ok)
        expect(returned_ids).to contain_exactly(allocatable.id)
      end
    end
  end

  context "for a user who may allocate nowhere" do
    let(:user) do
      create(:user,
             member_with_permissions: { viewing_project => %i[view_work_packages view_resource_planners] })
    end

    it "is forbidden" do
      expect(last_response).to have_http_status(:forbidden)
    end
  end
end
