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

RSpec.describe "User resource allocations requests", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  shared_let(:card_user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners] })
  end
  shared_let(:resource_planner) do
    create(:resource_planner, project:, principal: user, public: true,
                              start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31))
  end

  shared_let(:visible_wp) { create(:work_package, project:, subject: "Visible work") }
  shared_let(:foreign_wp) { create(:work_package, project: other_project, subject: "Secret work") }

  let(:path) { project_user_resource_allocations_path(project, card_user, resource_planner_id: resource_planner.id) }

  before do
    create(:resource_allocation, entity: visible_wp, principal: card_user)
    create(:resource_allocation, entity: foreign_wp, principal: card_user)
    login_as(user)
  end

  describe "GET index" do
    it "renders the utilization dialog with visible work package" do
      get path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.user_allocations_dialog.title"))
      expect(response.body).to include("Visible work")
    end

    it "lumps hidden work packages together" do
      get path, as: :turbo_stream

      expect(response.body).not_to include("Secret work")
      expect(response.body).to include(I18n.t("resource_management.user_allocations_dialog.other_work_packages.one"))
    end

    it "offers no allocation actions to a user who may not allocate" do
      get path, as: :turbo_stream

      expect(response.body).not_to include("/edit")
    end

    context "when the user may allocate" do
      shared_let(:user) do
        create(:user,
               member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
      end

      it "offers edit and allocate actions" do
        get path, as: :turbo_stream

        expect(response.body).to include(I18n.t("resource_management.user_allocations_dialog.allocate_work_package"))
        expect(response.body).to include(edit_project_resource_allocation_path(project,
                                                                               ResourceAllocation.find_by(entity: visible_wp)))
      end
    end
  end

  describe "authorization" do
    it "is forbidden without the view_resource_planners permission" do
      login_as(create(:user, member_with_permissions: { project => %i[view_work_packages] }))

      get path, as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "is not found for a user the current user cannot see" do
      hidden = create(:user)

      get project_user_resource_allocations_path(project, hidden, resource_planner_id: resource_planner.id),
          as: :turbo_stream

      expect(response).to have_http_status(:not_found)
    end
  end
end
