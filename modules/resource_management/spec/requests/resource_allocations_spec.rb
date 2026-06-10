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

  context "without the allocate_user_resources permission" do
    shared_let(:viewer) { create(:user, member_with_permissions: { project => %i[view_resource_planners] }) }

    before { login_as viewer }

    it "denies access to the new dialog" do
      get new_project_resource_allocation_path(project), as: :turbo_stream

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
end
