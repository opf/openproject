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

RSpec.describe "Global resource allocations", :skip_csrf, type: :rails_request,
                                                          with_ee: %i[resource_management] do
  shared_let(:allocatable) do
    create(:project, name: "Allocatable", enabled_module_names: %w[resource_management work_package_tracking])
  end
  # Visible, but the user may not allocate here.
  shared_let(:read_only) do
    create(:project, name: "Read only", enabled_module_names: %w[resource_management work_package_tracking])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             allocatable => %i[view_resource_planners view_work_packages allocate_user_resources],
             read_only => %i[view_resource_planners view_work_packages]
           },
           global_permissions: %i[view_global_resource_planners])
  end

  shared_let(:resource) do
    create(:user, firstname: "Rita", lastname: "Resource",
                  member_with_permissions: { allocatable => %i[view_work_packages] })
  end

  shared_let(:allocatable_wp) { create(:work_package, project: allocatable, subject: "Plannable work") }
  shared_let(:read_only_wp) { create(:work_package, project: read_only, subject: "Untouchable work") }

  before { login_as(user) }

  def allocation_params(work_package)
    {
      resource_allocation: {
        entity_type: "WorkPackage",
        entity_id: work_package.id,
        placeholder_or_user_id: resource.id,
        date_range: "2026-01-05 - 2026-01-09",
        allocated_hours: "10"
      }
    }
  end

  it "opens the new allocation dialog globally" do
    get new_resource_allocation_path, headers: { "Accept" => "text/vnd.turbo-stream.html" }

    expect(response).to have_http_status(:ok)
  end

  it "creates an allocation, taking the project from the work package" do
    expect do
      post resource_allocations_path, params: allocation_params(allocatable_wp), as: :turbo_stream
    end.to change(ResourceAllocation, :count).by(1)

    allocation = ResourceAllocation.last
    expect(allocation.entity).to eq(allocatable_wp)
    expect(allocation.project).to eq(allocatable)
    expect(allocation.principal).to eq(resource)
  end

  it "refuses a work package in a project the user may not allocate in" do
    expect do
      post resource_allocations_path, params: allocation_params(read_only_wp), as: :turbo_stream
    end.not_to change(ResourceAllocation, :count)
  end

  describe "allocating someone who does not work on the project" do
    # Visible to the allocator through the other project, but not a member of the
    # one the work package belongs to — the mistake a global planner invites.
    shared_let(:outsider) do
      create(:user, firstname: "Out", lastname: "Sider",
                    member_with_permissions: { read_only => %i[view_work_packages] })
    end

    def outsider_params
      allocation_params(allocatable_wp).tap do |params|
        params[:resource_allocation][:placeholder_or_user_id] = outsider.id
      end
    end

    it "is refused by name rather than reported as a blank assignee" do
      expect do
        post resource_allocations_path, params: outsider_params, as: :turbo_stream
      end.not_to change(ResourceAllocation, :count)

      expect(response.body).to include("is not a member of the work package")
      expect(response.body).not_to include("can&#39;t be blank")
    end

    it "warns about it in the form while the dialog is still open" do
      post refresh_form_resource_allocations_path, params: outsider_params, as: :turbo_stream

      expect(response.body).to include("Out Sider", "Allocatable")
    end
  end

  describe "an existing global allocation" do
    shared_let(:allocation) do
      create(:resource_allocation, entity: allocatable_wp, principal: resource, state: :allocated,
                                   start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9),
                                   allocated_time: 600)
    end

    it "can be edited through the global route" do
      get edit_resource_allocation_path(allocation), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
    end

    it "can be deleted through the global route" do
      expect do
        delete resource_allocation_path(allocation), as: :turbo_stream
      end.to change(ResourceAllocation, :count).by(-1)
    end

    it "lists the work package's allocations in the global dialog" do
      get work_package_resource_allocations_path(allocatable_wp),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
    end
  end
end
