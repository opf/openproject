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

RSpec.describe "Global user resource allocations requests",
               type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:alpha) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:beta) { create(:project, name: "Beta", enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:invisible) do
    create(:project, name: "Invisible", enabled_module_names: %w[resource_management work_package_tracking])
  end

  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             alpha => %i[view_resource_planners view_work_packages allocate_user_resources],
             beta => %i[view_resource_planners view_work_packages]
           },
           global_permissions: %i[view_global_resource_planners])
  end
  shared_let(:card_user) { create(:user, member_with_permissions: { alpha => %i[view_resource_planners] }) }

  shared_let(:planner) { create(:resource_planner, :global, principal: user, name: "Capacity") }
  shared_let(:card_view) { create(:resource_user_card, parent: planner, project: nil, principal: user) }

  shared_let(:alpha_wp) { create(:work_package, project: alpha, subject: "Alpha work") }
  shared_let(:beta_wp) { create(:work_package, project: beta, subject: "Beta work") }
  shared_let(:invisible_wp) { create(:work_package, project: invisible, subject: "Secret work") }

  shared_let(:alpha_allocation) { create(:resource_allocation, entity: alpha_wp, principal: card_user) }
  shared_let(:beta_allocation) { create(:resource_allocation, entity: beta_wp, principal: card_user) }
  shared_let(:invisible_allocation) { create(:resource_allocation, entity: invisible_wp, principal: card_user) }

  let(:path) { user_resource_allocations_path(card_user, resource_planner_view_id: card_view.id) }

  before { login_as(user) }

  it "lists the allocations of every project the viewer can see" do
    get path, as: :turbo_stream

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Alpha work", "Beta work")
  end

  it "lumps together only what the viewer may not see" do
    get path, as: :turbo_stream

    expect(response.body).not_to include("Secret work")
    expect(response.body).to include(I18n.t("resource_management.user_allocations_dialog.other_work_packages.one"))
  end

  it "offers the edit action on the global route where the viewer may allocate" do
    get path, as: :turbo_stream

    expect(response.body).to include(edit_resource_allocation_path(alpha_allocation))
  end

  it "offers no edit action in a project the viewer may not allocate in" do
    get path, as: :turbo_stream

    expect(response.body).not_to include(edit_resource_allocation_path(beta_allocation))
  end
end
