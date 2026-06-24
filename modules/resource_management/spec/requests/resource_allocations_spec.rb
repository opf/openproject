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

RSpec.describe "ResourceAllocations requests",
               :skip_csrf,
               type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %w[resource_management work_package_tracking]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners allocate_user_resources view_work_packages] })
  end
  shared_let(:assignee) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }
  shared_let(:work_package) { create(:work_package, project:) }

  before { login_as user }

  describe "GET new" do
    it "opens the dialog on the kind-selection step" do
      get new_project_resource_allocation_path(project), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="principal"')
      expect(response.body).to include('value="filter"')
    end
  end

  describe "GET step" do
    context "with allocation_kind=principal" do
      it "renders the allocation step with a user picker" do
        get step_project_resource_allocations_path(project, allocation_kind: "principal"), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        # Autocompleters render as Angular custom elements carrying the field
        # name in `data-input-name` rather than a plain `name` attribute.
        expect(response.body).to include("opce-user-autocompleter")
        expect(response.body).to include("resource_allocation[principal_id]")
        expect(response.body).to include("resource_allocation[entity_id]")
        expect(response.body).to include("resource_allocation[allocated_hours]")
      end
    end

    context "with allocation_kind=filter" do
      it "renders the allocation step with a filter name and the filter form" do
        get step_project_resource_allocations_path(project, allocation_kind: "filter"), as: :turbo_stream

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("resource_allocation[filter_name]")
        expect(response.body).to include('name="filters"')
      end
    end
  end

  describe "GET refresh_form" do
    shared_let(:dated_work_package) do
      create(:work_package, project:, start_date: Date.new(2026, 1, 15), due_date: Date.new(2026, 2, 20))
    end

    def refresh(start_date:, end_date:, entity_id: dated_work_package.id)
      get refresh_form_project_resource_allocations_path(project),
          params: {
            allocation_kind: "principal",
            resource_allocation: {
              principal_id: assignee.id,
              entity_type: "WorkPackage",
              entity_id:,
              start_date:,
              end_date:,
              allocated_hours: "40h"
            }
          },
          as: :turbo_stream
    end

    it "streams the inline warning banner when the dates fall outside the work package" do
      refresh(start_date: "2026-02-24", end_date: "2026-02-25")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("outside of the work")
      # Only the banner is replaced; the form and its focused date field stay untouched.
      expect(response.body).not_to include("opce-user-autocompleter")
    end

    it "streams an empty banner when the dates fit" do
      refresh(start_date: "2026-01-20", end_date: "2026-01-21")

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("outside of the work")
    end

    it "does not leak the dates of a work package the user cannot see" do
      invisible_work_package = create(:work_package, project: create(:project),
                                                     start_date: Date.new(2026, 1, 15),
                                                     due_date: Date.new(2026, 2, 20))

      # The same dates trigger the warning against a visible work package.
      refresh(start_date: "2026-02-24", end_date: "2026-02-25", entity_id: invisible_work_package.id)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("outside of the work")
      expect(response.body).not_to include(I18n.l(Date.new(2026, 1, 15)))
      expect(response.body).not_to include(I18n.l(Date.new(2026, 2, 20)))
    end
  end

  describe "POST create" do
    context "for an explicit user" do
      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: assignee.id,
                 entity_type: "WorkPackage",
                 entity_id: work_package.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "creates a resource allocation for the principal" do
        expect { perform }.to change(ResourceAllocation, :count).by(1)

        allocation = ResourceAllocation.last
        expect(allocation.entity).to eq(work_package)
        expect(allocation.principal).to eq(assignee)
        expect(allocation).to be_principal_explicit
        expect(allocation.allocated_time).to eq(40 * 60)
        expect(allocation.filter_name).to be_nil
        expect(allocation.user_filter).to eq([])
        expect(allocation.requested_by).to eq(user)
      end

      it "refreshes the open allocations list and announces the change for the planner table" do
        perform

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('target="resource-allocations-list-component"')
        expect_allocation_change_announced_for(work_package)
      end
    end

    context "for a filter-criteria placeholder" do
      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "filter",
               filters: [{ login: { operator: "~", values: ["dev"] } }].to_json,
               resource_allocation: {
                 filter_name: "Full stack Developer (DE-EN)",
                 entity_type: "WorkPackage",
                 entity_id: work_package.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "creates a placeholder allocation carrying the user filter" do
        expect { perform }.to change(ResourceAllocation, :count).by(1)

        allocation = ResourceAllocation.last
        expect(allocation.principal).to be_nil
        expect(allocation).not_to be_principal_explicit
        expect(allocation).to be_needs_principal_assignment
        expect(allocation.filter_name).to eq("Full stack Developer (DE-EN)")
        expect(allocation.user_filter.map(&:name)).to contain_exactly(:login)
        expect(allocation.user_filter.first.values).to eq(["dev"])
      end
    end

    context "with invalid input" do
      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: assignee.id,
                 entity_type: "WorkPackage",
                 entity_id: work_package.id,
                 start_date: "2026-03-03",
                 end_date: "2026-03-02", # before start_date
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "does not create an allocation and re-renders the step" do
        expect { perform }.not_to change(ResourceAllocation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a work package the user cannot reach in this project" do
      shared_let(:other_work_package) { create(:work_package) }

      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: assignee.id,
                 entity_type: "WorkPackage",
                 entity_id: other_work_package.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "does not create an allocation and re-renders the step" do
        expect { perform }.not_to change(ResourceAllocation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with a principal who is not a member of the project" do
      shared_let(:non_member) { create(:user) }

      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: non_member.id,
                 entity_type: "WorkPackage",
                 entity_id: work_package.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "does not create an allocation and re-renders the step" do
        expect { perform }.not_to change(ResourceAllocation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with an entity type outside the allow-list" do
      subject(:perform) do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: assignee.id,
                 entity_type: "Project",
                 entity_id: project.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end

      it "does not create an allocation and re-renders the step" do
        expect { perform }.not_to change(ResourceAllocation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the allocation dates fall outside the work package's dates" do
      shared_let(:dated_work_package) do
        create(:work_package, project:, start_date: Date.new(2026, 1, 15), due_date: Date.new(2026, 2, 20))
      end

      let(:base_params) do
        {
          allocation_kind: "principal",
          resource_allocation: {
            principal_id: assignee.id,
            entity_type: "WorkPackage",
            entity_id: dated_work_package.id,
            start_date: "2026-02-24", # after the work package's finish date
            end_date: "2026-02-25",
            allocated_hours: "40h"
          }
        }
      end

      # Falling outside the work package's dates no longer blocks creation; it is
      # surfaced as an inline warning in the editable step instead.
      it "creates the allocation directly without a confirmation step" do
        expect do
          post project_resource_allocations_path(project), params: base_params, as: :turbo_stream
        end.to change(ResourceAllocation, :count).by(1)

        expect(ResourceAllocation.last.entity).to eq(dated_work_package)
      end
    end

    context "when the allocation dates fall within the work package's dates" do
      shared_let(:dated_work_package) do
        create(:work_package, project:, start_date: Date.new(2026, 1, 15), due_date: Date.new(2026, 2, 20))
      end

      it "creates the allocation directly without confirmation" do
        expect do
          post project_resource_allocations_path(project),
               params: {
                 allocation_kind: "principal",
                 resource_allocation: {
                   principal_id: assignee.id,
                   entity_type: "WorkPackage",
                   entity_id: dated_work_package.id,
                   start_date: "2026-01-20",
                   end_date: "2026-01-21",
                   allocated_hours: "40h"
                 }
               },
               as: :turbo_stream
        end.to change(ResourceAllocation, :count).by(1)
      end
    end

    context "when the allocation would overbook the assigned user" do
      shared_let(:working_assignee) do
        create(:user, member_with_permissions: { project => %i[view_work_packages] }).tap do |assignee|
          # Mon-Fri 8h => 480 minutes/day of capacity.
          create(:user_working_hours, user: assignee, valid_from: Date.new(2025, 1, 1))
        end
      end

      # 40h (2400 min) across Mon-Tue (960 min of capacity) overbooks the user.
      let(:base_params) do
        {
          allocation_kind: "principal",
          resource_allocation: {
            principal_id: working_assignee.id,
            entity_type: "WorkPackage",
            entity_id: work_package.id,
            start_date: "2026-03-02",
            end_date: "2026-03-03",
            allocated_hours: "40h"
          }
        }
      end

      it "does not create yet and renders the overbooking confirmation step" do
        expect do
          post project_resource_allocations_path(project), params: base_params, as: :turbo_stream
        end.not_to change(ResourceAllocation, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t("resource_management.allocate_resource_dialog.overbooking.title"))
        # The user's compact working schedule is shown in the description. The
        # availability factor is omitted at 100%.
        expect(response.body).to include("Mon-Fri 8h")
        expect(response.body).not_to include("available for project work")
        expect(response.body).to include('name="confirmed"')
      end

      it "shows the availability factor when the user is only partially available for project work" do
        partially_available = create(:user, member_with_permissions: { project => %i[view_work_packages] })
        create(:user_working_hours, user: partially_available, valid_from: Date.new(2025, 1, 1), availability_factor: 80)

        params = base_params.deep_merge(resource_allocation: { principal_id: partially_available.id })
        post project_resource_allocations_path(project), params:, as: :turbo_stream

        expect(response.body).to include("Mon-Fri 8h (80% available for project work)")
      end

      it "lists each schedule with its effective dates when the schedule changes during the period" do
        # Switches to Mon-Fri 6h at 80% on the second day of the allocation.
        create(:user_working_hours, user: working_assignee, valid_from: Date.new(2026, 3, 3),
                                    monday: 360, tuesday: 360, wednesday: 360, thursday: 360, friday: 360,
                                    availability_factor: 80)

        post project_resource_allocations_path(project), params: base_params, as: :turbo_stream

        expect(response.body).to include(
          "Mon-Fri 8h until #{I18n.l(Date.new(2026, 3, 2))}, " \
          "then Mon-Fri 6h (80% available for project work)"
        )
      end

      it "creates the allocation once confirmed" do
        expect do
          post project_resource_allocations_path(project),
               params: base_params.merge(confirmed: "1"),
               as: :turbo_stream
        end.to change(ResourceAllocation, :count).by(1)
      end

      it "collapses allocations of work packages the requester cannot see into a lump sum" do
        hidden_work_package = create(:work_package, project: create(:project), subject: "Confidential rocket plans")
        create(:resource_allocation,
               principal: working_assignee,
               entity: hidden_work_package,
               allocated_time: 600,
               start_date: Date.new(2026, 3, 2),
               end_date: Date.new(2026, 3, 3))

        post project_resource_allocations_path(project), params: base_params, as: :turbo_stream

        expect(response.body).to include(I18n.t("resource_management.allocate_resource_dialog.overbooking.hidden_work"))
        expect(response.body).to include("10h")
        expect(response.body).not_to include("Confidential rocket plans")
      end
    end

    context "when the assigned user has no working time configured" do
      it "skips the overbooking check and creates directly" do
        expect do
          post project_resource_allocations_path(project),
               params: {
                 allocation_kind: "principal",
                 resource_allocation: {
                   principal_id: assignee.id,
                   entity_type: "WorkPackage",
                   entity_id: work_package.id,
                   start_date: "2026-03-02",
                   end_date: "2026-03-03",
                   allocated_hours: "40h"
                 }
               },
               as: :turbo_stream
        end.to change(ResourceAllocation, :count).by(1)
      end
    end
  end

  describe "GET edit" do
    shared_let(:allocation) { create(:resource_allocation, entity: work_package, principal: assignee) }

    it "opens the edit dialog with the allocation form" do
      get edit_project_resource_allocation_path(project, allocation), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.edit_allocation_dialog.title"))
      expect(response.body).to include("resource_allocation[allocated_hours]")
    end

    context "for an allocation of another project's work package" do
      let(:other_allocation) { create(:resource_allocation) }

      it "is not found" do
        get edit_project_resource_allocation_path(project, other_allocation), as: :turbo_stream

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "PATCH update" do
    let!(:allocation) do
      create(:resource_allocation, entity: work_package, principal: assignee, allocated_time: 600)
    end

    def perform(allocated_hours: "16h")
      patch project_resource_allocation_path(project, allocation),
            params: {
              allocation_kind: "principal",
              resource_allocation: {
                principal_id: assignee.id,
                entity_type: "WorkPackage",
                entity_id: work_package.id,
                start_date: "2026-03-02",
                end_date: "2026-03-06",
                allocated_hours:
              }
            },
            as: :turbo_stream
    end

    it "updates the allocation and confirms it" do
      perform

      expect(response).to have_http_status(:ok)
      expect(allocation.reload.allocated_time).to eq(16 * 60)
      expect(allocation.start_date).to eq(Date.new(2026, 3, 2))
      expect(allocation.end_date).to eq(Date.new(2026, 3, 6))
      expect(response.body).to include(I18n.t("resource_management.edit_allocation_dialog.success_message"))
    end

    it "announces the change so the planner table can refresh" do
      perform

      expect_allocation_change_announced_for(work_package)
    end

    context "with invalid input" do
      it "re-renders the form unprocessable and keeps the allocation unchanged" do
        perform(allocated_hours: "")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(allocation.reload.allocated_time).to eq(600)
      end

      # Regression: an absurdly large value used to overflow the integer column
      # and raise ActiveModel::RangeError (500) instead of failing validation.
      it "rejects a value above the maximum with an hours-formatted message" do
        perform(allocated_hours: "999999999999h")

        expect(response).to have_http_status(:unprocessable_entity)
        expect(allocation.reload.allocated_time).to eq(600)
        expect(response.body).to include(
          DurationConverter.output(ResourceAllocation::MAX_ALLOCATED_TIME / 60.0)
        )
      end
    end

    context "when the update would overbook the assigned user" do
      shared_let(:working_assignee) do
        create(:user, member_with_permissions: { project => %i[view_work_packages] }).tap do |member|
          # Mon-Fri 8h => 480 minutes/day of capacity.
          create(:user_working_hours, user: member, valid_from: Date.new(2025, 1, 1))
        end
      end

      # Books 10h across Mon-Tue (16h of capacity).
      let!(:allocation) do
        create(:resource_allocation,
               entity: work_package, principal: working_assignee,
               start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 3), allocated_time: 600)
      end

      def perform(extra = {})
        patch project_resource_allocation_path(project, allocation),
              params: {
                allocation_kind: "principal",
                resource_allocation: {
                  principal_id: working_assignee.id,
                  entity_type: "WorkPackage",
                  entity_id: work_package.id,
                  start_date: "2026-03-02",
                  end_date: "2026-03-03",
                  allocated_hours: "40h"
                }
              }.deep_merge(extra),
              as: :turbo_stream
      end

      it "does not save yet and renders the overbooking confirmation step" do
        perform

        expect(response).to have_http_status(:ok)
        expect(allocation.reload.allocated_time).to eq(600)
        expect(response.body).to include(I18n.t("resource_management.allocate_resource_dialog.overbooking.title"))
        expect(response.body).to include('name="confirmed"')
      end

      it "applies the update once confirmed" do
        perform(confirmed: "1")

        expect(allocation.reload.allocated_time).to eq(40 * 60)
        expect(response.body).to include(I18n.t("resource_management.edit_allocation_dialog.success_message"))
      end

      it "returns to the pre-filled edit form when going back from the confirmation" do
        perform(back: "1")

        expect(response).to have_http_status(:ok)
        expect(allocation.reload.allocated_time).to eq(600)
        expect(response.body).to include("resource_allocation[allocated_hours]")
      end

      it "does not count the allocation's previous booking against its own update" do
        # 16h exactly fills Mon-Tue only if the allocation's persisted 10h are
        # excluded from the check; no confirmation step expected.
        perform(resource_allocation: { allocated_hours: "16h" })

        expect(allocation.reload.allocated_time).to eq(16 * 60)
        expect(response.body).to include(I18n.t("resource_management.edit_allocation_dialog.success_message"))
      end
    end
  end

  describe "DELETE destroy" do
    let!(:allocation) { create(:resource_allocation, entity: work_package, principal: assignee) }

    it "deletes the allocation and confirms it" do
      expect do
        delete project_resource_allocation_path(project, allocation), as: :turbo_stream
      end.to change(ResourceAllocation, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("resource_management.work_package_allocations_dialog.delete_success"))
    end

    it "refreshes the open allocations list and announces the change for the planner table" do
      delete project_resource_allocation_path(project, allocation), as: :turbo_stream

      expect(response.body).to include('target="resource-allocations-list-component"')
      expect_allocation_change_announced_for(work_package)
    end
  end

  context "without the allocate_user_resources permission" do
    shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }
    shared_let(:allocation) { create(:resource_allocation, entity: work_package, principal: assignee) }

    before { login_as viewer }

    it "denies access to the new dialog" do
      get new_project_resource_allocation_path(project), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "denies access to the edit dialog" do
      get edit_project_resource_allocation_path(project, allocation), as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "denies updating an allocation" do
      patch project_resource_allocation_path(project, allocation),
            params: { allocation_kind: "principal", resource_allocation: { allocated_hours: "1h" } },
            as: :turbo_stream

      expect(response).to have_http_status(:forbidden)
    end

    it "denies deleting an allocation" do
      expect do
        delete project_resource_allocation_path(project, allocation), as: :turbo_stream
      end.not_to change(ResourceAllocation, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "denies creating an allocation" do
      expect do
        post project_resource_allocations_path(project),
             params: {
               allocation_kind: "principal",
               resource_allocation: {
                 principal_id: assignee.id,
                 entity_type: "WorkPackage",
                 entity_id: work_package.id,
                 start_date: "2026-03-02",
                 end_date: "2026-03-03",
                 allocated_hours: "40h"
               }
             },
             as: :turbo_stream
      end.not_to change(ResourceAllocation, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "opened from a user's utilization dialog" do
    shared_let(:resource_planner) do
      create(:resource_planner, project:, principal: user,
                                start_date: Date.new(2026, 3, 1), end_date: Date.new(2026, 3, 31))
    end
    let(:user_dialog_id) { ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent::DIALOG_ID }

    it "replaces the utilization dialog and opens the allocation step prefilled for the user" do
      get new_project_resource_allocation_path(project, principal_id: assignee.id,
                                                        resource_planner_id: resource_planner.id),
          as: :turbo_stream

      # The user dialog is closed and the kind step is skipped
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('action="closeDialog"')
      expect(response.body).to include("##{user_dialog_id}")
      expect(response.body).not_to include('value="filter"')
    end

    it "reopens a refreshed utilization dialog after a successful create" do
      post project_resource_allocations_path(project, resource_planner_id: resource_planner.id),
           params: {
             allocation_kind: "principal",
             resource_allocation: {
               principal_id: assignee.id, entity_type: "WorkPackage", entity_id: work_package.id,
               start_date: "2026-03-02", end_date: "2026-03-03", allocated_hours: "40h"
             }
           },
           as: :turbo_stream

      expect(response.body).to include(user_dialog_id)
      expect(response.body).to include(I18n.t("resource_management.user_allocations_dialog.title"))
    end
  end

  # The controller emits a `dispatchEvent` turbo stream carrying the changed
  # work package so an open resource planner table can reload it.
  def expect_allocation_change_announced_for(work_package)
    event = Nokogiri::HTML5.fragment(response.body).at_css('turbo-stream[action="dispatchEvent"]')

    expect(event).to be_present
    expect(event["event-name"]).to eq("resource-allocations:changed")
    expect(JSON.parse(event["detail"])).to eq("work_package_id" => work_package.id)
  end
end
