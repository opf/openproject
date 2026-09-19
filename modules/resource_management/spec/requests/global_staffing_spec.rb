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

RSpec.describe "Global staffing", :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:busy) do
    create(:project, name: "Busy project", enabled_module_names: %w[resource_management work_package_tracking])
  end
  shared_let(:quiet) do
    create(:project, name: "Quiet project", enabled_module_names: %w[resource_management work_package_tracking])
  end
  # Staffable work, but the user may not staff here.
  shared_let(:forbidden) do
    create(:project, name: "Forbidden project", enabled_module_names: %w[resource_management work_package_tracking])
  end

  shared_let(:user) do
    create(:user, member_with_permissions: {
             busy => %i[view_resource_planners view_work_packages assign_users_to_generic_allocations],
             quiet => %i[view_resource_planners view_work_packages assign_users_to_generic_allocations],
             forbidden => %i[view_resource_planners view_work_packages]
           })
  end

  shared_let(:busy_wp) { create(:work_package, project: busy, subject: "Needs staffing") }
  shared_let(:forbidden_wp) { create(:work_package, project: forbidden, subject: "Secret staffing") }

  shared_let(:busy_allocation) do
    create(:resource_allocation, :with_user_filter, entity: busy_wp, allocated_time: 600,
                                                    start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9))
  end
  shared_let(:forbidden_allocation) do
    create(:resource_allocation, :with_user_filter, entity: forbidden_wp, allocated_time: 600,
                                                    start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9))
  end

  before { login_as(user) }

  it "renders a section for every project the user may staff in" do
    get resource_management_staffing_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Busy project", "Quiet project")
  end

  it "omits projects the user may not staff in" do
    get resource_management_staffing_path

    expect(response.body).not_to include("Forbidden project", "Secret staffing")
  end

  it "collapses a project with nothing to staff" do
    get resource_management_staffing_path

    expect(response.body)
      .to have_css("collapsible-section#staffing-project-#{quiet.id}.CollapsibleSection--collapsed", visible: :all)
    expect(response.body)
      .to have_no_css("collapsible-section#staffing-project-#{busy.id}.CollapsibleSection--collapsed", visible: :all)
  end

  it "links its rows back to the global staffing routes" do
    get resource_management_staffing_path

    expect(response.body).to include(resource_management_staffing_assign_path(busy_allocation))
  end

  context "without the permission anywhere" do
    before { login_as(create(:user, member_with_permissions: { busy => %i[view_resource_planners] })) }

    it "is forbidden" do
      get resource_management_staffing_path

      expect(response).to have_http_status(:forbidden)
    end
  end
end
