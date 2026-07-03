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

RSpec.describe "Staffing requests",
               :skip_csrf, type: :rails_request, with_ee: %i[resource_management] do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[view_resource_planners assign_users_to_generic_allocations view_work_packages]
           })
  end
  shared_let(:work_package) { create(:work_package, project:) }

  # Two generic, unassigned allocations with different start dates.
  shared_let(:later_allocation) do
    create(:resource_allocation, :with_user_filter, entity: work_package,
                                                    filter_name: "Later developer",
                                                    start_date: Date.new(2026, 3, 1), end_date: Date.new(2026, 3, 31))
  end
  shared_let(:earlier_allocation) do
    create(:resource_allocation, :with_user_filter, entity: work_package,
                                                    filter_name: "Earlier developer",
                                                    start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31))
  end

  # A user the filter selects (developer who speaks German), member of the project.
  shared_let(:matching_user) do
    create(:user, firstname: "Mona", lastname: "Matcher",
                  member_with_permissions: { project => %i[view_work_packages] })
  end

  # Sets a user's custom fields so the generic allocations' filter selects them.
  def mark_matching(candidate)
    job_title = UserCustomField.find_by(name: "Job title")
    language = UserCustomField.find_by(name: "Spoken language")
    candidate.custom_field_values = {
      job_title.id => job_title.custom_options.find_by(value: "Developer").id,
      language.id => [language.custom_options.find_by(value: "German").id]
    }
    candidate.save!
    candidate
  end

  before do
    mark_matching(matching_user)
    create(:user_working_hours, user: matching_user, valid_from: Date.new(2025, 1, 1))

    login_as user
  end

  describe "GET index" do
    it "lists the unassigned generic allocations sorted by start date" do
      get project_staffing_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Earlier developer", "Later developer")
      expect(response.body.index("Earlier developer")).to be < response.body.index("Later developer")
      # The filter criteria are summarized alongside the free-text name.
      expect(response.body).to include("Job title", "Spoken language")
    end

    it "warns about an allocation that has already started" do
      travel_to(Date.new(2026, 2, 1)) do
        get project_staffing_path(project)
      end

      expect(response.body).to include(I18n.t("resource_management.staffing.starts_in_past"))
    end

    context "without the assign permission" do
      let(:other) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

      it "is forbidden" do
        login_as other
        get project_staffing_path(project)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "the row context menu" do
    it "offers Assign inside a frame that reloads when an allocation changes" do
      get project_staffing_path(project)

      expect(response.body).to include(I18n.t("resource_management.staffing.assign"))
      # Edit and delete require the allocate permission, which this user lacks.
      expect(response.body).not_to include(edit_project_resource_allocation_path(project, earlier_allocation))
      expect(response.body).not_to include(I18n.t("resource_management.staffing.delete_confirmation"))
      # The list sits in a frame that reloads when an allocation changes elsewhere.
      expect(response.body).to include("op-dispatched:resource-allocations:changed")
    end

    context "with the allocate permission" do
      let(:manager) do
        create(:user,
               member_with_permissions: {
                 project => %i[view_resource_planners assign_users_to_generic_allocations
                               allocate_user_resources view_work_packages]
               })
      end

      it "also offers Edit and Delete" do
        login_as manager
        get project_staffing_path(project)

        expect(response.body).to include(edit_project_resource_allocation_path(project, earlier_allocation))
        expect(response.body).to include(I18n.t("resource_management.staffing.delete_confirmation"))
      end
    end
  end

  describe "the sidebar menu" do
    it "shows the Staffing entry for a user with the permission" do
      get menu_project_resource_planners_path(project, origin_controller: "resource_management/staffing")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.staffing.menu_item"))
      expect(response.body).to include(project_staffing_path(project))
    end

    context "without the assign permission" do
      let(:other) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

      it "hides the Staffing entry" do
        login_as other
        get menu_project_resource_planners_path(project)

        expect(response.body).not_to include(I18n.t("resource_management.staffing.menu_item"))
      end
    end
  end

  describe "GET assign (dialog)" do
    it "opens the dialog listing matching project members" do
      get project_staffing_assign_path(project, earlier_allocation), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mona Matcher")
      expect(response.body).to include('name="principal_id"')
      # The criteria the candidates are matched against are summarized.
      expect(response.body).to include(I18n.t("resource_management.assignment_dialog.filter_criteria"))
      expect(response.body).to include("Job title")
      # The hours still available in the period are shown for the candidate.
      expect(response.body).to include("available")
      # The avatar is the principal component that carries the user hover card.
      expect(response.body).to include("opce-principal")
      # The allocation context: work package, period and requested time, each
      # rendered in the same muted label/value style.
      expect(response.body).to include(work_package.subject)
      expect(response.body).to include(I18n.t("resource_management.staffing.columns.requested_time"))
      expect(response.body).to include(DurationConverter.output(earlier_allocation.allocated_hours))
    end

    it "warns about a candidate who has no work schedule set up" do
      mark_matching(create(:user, firstname: "Nora", lastname: "NoSchedule",
                                  member_with_permissions: { project => %i[view_work_packages] }))

      get project_staffing_assign_path(project, earlier_allocation), as: :turbo_stream

      expect(response.body).to include("Nora NoSchedule")
      expect(response.body).to include(I18n.t("resource_management.assignment_dialog.no_schedule"))
    end

    it "explains the available vs required hours for an overbooked candidate" do
      # Mona already has more booked in January than she can work, so the
      # prospective allocation overbooks her.
      create(:resource_allocation, principal: matching_user, entity: work_package,
                                   start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31),
                                   allocated_time: 300 * 60)

      get project_staffing_assign_path(project, earlier_allocation), as: :turbo_stream

      expect(response.body).to include("the work package requires")
    end
  end

  describe "PUT assign" do
    def assign(allocation, params = {})
      put project_staffing_assign_path(project, allocation),
          params: { principal_id: matching_user.id }.merge(params),
          as: :turbo_stream
    end

    it "assigns the user while keeping the allocation generic" do
      assign(earlier_allocation)

      expect(response).to have_http_status(:ok)
      earlier_allocation.reload
      expect(earlier_allocation.principal).to eq(matching_user)
      expect(earlier_allocation.principal_assigned_by).to eq(user)
      expect(earlier_allocation.principal_explicit).to be(false)
      expect(earlier_allocation.filter_name).to eq("Earlier developer")
      expect(earlier_allocation.user_filter).to be_present
    end

    it "rejects a user that does not match the filter" do
      non_matching = create(:user, member_with_permissions: { project => %i[view_work_packages] })

      assign(earlier_allocation, principal_id: non_matching.id)

      expect(earlier_allocation.reload.principal).to be_nil
    end

    context "when the assignment would overbook the user" do
      # matching_user already has a schedule (Mon-Fri 8h ≈ 176h for January).
      # An existing allocation that already fills the period.
      shared_let(:existing) do
        create(:resource_allocation, principal: matching_user, entity: work_package,
                                     start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 1, 31),
                                     allocated_time: 200 * 60)
      end

      before do
        earlier_allocation.update!(allocated_time: 200 * 60)
      end

      it "shows the overtime confirmation first, then persists on confirm" do
        assign(earlier_allocation)
        expect(response.body).to include(I18n.t("resource_management.allocate_resource_dialog.overbooking.title"))
        expect(earlier_allocation.reload.principal).to be_nil

        assign(earlier_allocation, confirmed: "1")
        expect(earlier_allocation.reload.principal).to eq(matching_user)
      end
    end
  end
end
