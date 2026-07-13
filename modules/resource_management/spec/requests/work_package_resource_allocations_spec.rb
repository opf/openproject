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

RSpec.describe "WorkPackage resource allocations requests", type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_resource_planners view_work_packages] })
  end
  # A project member the current user can see.
  shared_let(:assignee) do
    create(:user, firstname: "Sarah", lastname: "Smith", member_with_permissions: { project => %i[view_work_packages] })
  end
  # No shared project or group, so invisible to the (non-admin) current user.
  shared_let(:hidden_user) { create(:user, firstname: "Secret", lastname: "Agent") }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:path) { project_work_package_resource_allocations_path(project, work_package) }

  before { login_as(user) }

  describe "GET index" do
    before do
      create(:resource_allocation, entity: work_package, principal: assignee, allocated_time: 720)
      create(:resource_allocation, entity: work_package, principal: hidden_user, allocated_time: 300)
      create(:resource_allocation,
             entity: work_package, principal_explicit: false, principal: nil, filter_name: "Full stack developer")
    end

    it "renders the allocations dialog" do
      get path, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.work_package_allocations_dialog.title"))
    end

    # An inline delete submits a form inside the dialog; without this flag the
    # global submit-end handler would close the dialog on success.
    it "keeps the dialog open across in-dialog form submissions" do
      get path, as: :turbo_stream

      dialog = Nokogiri::HTML5.fragment(response.body).at_css("dialog")
      expect(dialog["data-keep-open-on-submit"]).to eq("true")
    end

    it "names the visible member and the filter allocation" do
      get path, as: :turbo_stream

      expect(response.body).to include("Sarah Smith")
      expect(response.body).to include("Full stack developer")
    end

    it "lists the invisible member anonymously, never revealing the name" do
      get path, as: :turbo_stream

      expect(response.body).not_to include("Secret Agent")
      expect(response.body).to include(I18n.t("resource_management.work_package_allocations_dialog.hidden_user"))
    end

    it "offers no row actions to a user who may not manage allocations" do
      get path, as: :turbo_stream

      expect(response.body).not_to include("/edit")
    end

    context "when the user may manage allocations" do
      shared_let(:manager) do
        create(:user,
               member_with_permissions: {
                 project => %i[view_resource_planners allocate_user_resources view_work_packages]
               })
      end

      before { login_as(manager) }

      it "offers edit and delete row actions" do
        allocation = ResourceAllocation.find_by(principal: assignee)

        get path, as: :turbo_stream

        expect(response.body).to include(edit_project_resource_allocation_path(project, allocation))
        expect(response.body).to include(I18n.t(:button_delete))
      end
    end

    context "when an assigned user is overbooked" do
      let!(:overbooked_allocation) do
        create(:resource_allocation,
               entity: work_package, principal: assignee,
               start_date: Date.new(2026, 2, 2), end_date: Date.new(2026, 2, 2), allocated_time: 16 * 60)
      end

      before do
        create(:user_working_hours, user: assignee, valid_from: Date.new(2025, 1, 1))
      end

      it "flags the overbooked allocation with a warning" do
        get path, as: :turbo_stream

        expect(response.body).to include("resource-allocation-overbooked-#{overbooked_allocation.id}")
      end
    end
  end

  describe "authorization" do
    context "without the view_resource_planners permission" do
      shared_let(:other_user) do
        create(:user, member_with_permissions: { project => %i[view_work_packages] })
      end

      before { login_as(other_user) }

      it "is forbidden" do
        get path, as: :turbo_stream

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when the work package is not visible to the user" do
      let(:other_project) { create(:project, enabled_module_names: %w[resource_management]) }
      let(:invisible_work_package) { create(:work_package, project: other_project) }

      it "returns not found" do
        get project_work_package_resource_allocations_path(project, invisible_work_package), as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
