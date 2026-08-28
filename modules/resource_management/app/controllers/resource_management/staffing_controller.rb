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
module ::ResourceManagement
  # Lists generic (filter-based) allocations in the project still awaiting a
  # user, and assigns real users to them. Keeps the allocation's `user_filter`,
  # `filter_name` and `principal_explicit: false` untouched — only `principal`
  # and `principal_assigned_by` change.
  class StaffingController < BaseController
    include OpTurbo::ComponentStream

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_allocation, only: %i[assign_form assign]

    def index
      @list_component = list_component
    end

    def assign_form
      respond_with_dialog ResourceAllocations::AssignmentDialogComponent.new(
        project: @project,
        allocation: @allocation,
        candidates: candidates_for(@allocation)
      )
    end

    def assign
      # The confirmation step's "Back" button returns to the candidate list.
      return render_candidate_step if params[:back].present?

      principal = candidate_principal
      return render_candidate_step(error: t("resource_management.assignment_dialog.select_user")) if principal.nil?

      @allocation.principal = principal
      @allocation.principal_assigned_by = current_user

      return render_warning_step(principal) if needs_confirmation?(principal)

      persist_assignment(principal)
    end

    private

    def persist_assignment(principal)
      call = ResourceAllocations::AssignService
               .new(user: current_user, model: @allocation)
               .call(principal:, principal_assigned_by: current_user)

      if call.success?
        render_assign_success
      else
        render_candidate_step(error: call.errors.full_messages.to_sentence, status: :unprocessable_entity)
      end
    end

    def render_assign_success
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("resource_management.staffing.success_message")
      )
      close_dialog_via_turbo_stream(ResourceAllocations::AssignmentDialogComponent::DIALOG_ID)
      replace_via_turbo_stream(component: list_component)
      respond_with_turbo_streams
    end

    def render_candidate_step(error: nil, status: :ok)
      replace_via_turbo_stream(
        component: ResourceAllocations::AssignmentStep::FormComponent.new(
          project: @project, allocation: @allocation, candidates: candidates_for(@allocation), error:
        ),
        status:
      )
      replace_via_turbo_stream(component: ResourceAllocations::AssignmentStep::FooterComponent.new)
      respond_with_turbo_streams(status:)
    end

    def render_warning_step(principal)
      ranges = overbooked_ranges(principal)

      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FormComponent.new(
          allocation: @allocation,
          project: @project,
          allocation_kind: "principal",
          form_values: {},
          overbooked_ranges: ranges,
          working_schedules: working_schedules(principal, ranges),
          body_id: ResourceAllocations::AssignmentDialogComponent::BODY_ID,
          form_id: ResourceAllocations::AssignmentDialogComponent::FORM_ID,
          form_url: project_staffing_assign_path(@project, @allocation),
          form_method: :put,
          hidden_fields: { "principal_id" => principal.id }
        )
      )
      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FooterComponent.new(
          dialog_id: ResourceAllocations::AssignmentDialogComponent::DIALOG_ID,
          form_id: ResourceAllocations::AssignmentDialogComponent::FORM_ID,
          footer_id: ResourceAllocations::AssignmentDialogComponent::FOOTER_ID,
          submit_label: I18n.t("resource_management.assignment_dialog.confirm_overtime")
        )
      )
      respond_with_turbo_streams
    end

    # A confirmation step is shown only when the assignment would overbook the
    # selected user (and only when their capacity is known).
    def needs_confirmation?(principal)
      return false if params[:confirmed].present?

      overbooked_ranges(principal).any?
    end

    def overbooked_ranges(principal)
      @overbooked_ranges ||= compute_overbooked_ranges(principal)
    end

    def compute_overbooked_ranges(principal)
      return [] unless UserWorkingHours.for_user(principal).exists?
      return [] if @allocation.allocated_time.to_i <= 0

      ResourceAllocations::Availability.new(user: principal).overbooking_with(
        start_date: @allocation.start_date,
        end_date: @allocation.end_date,
        minutes: @allocation.allocated_time,
        work_package_id: @allocation.entity_id,
        exclude_id: @allocation.id
      )
    end

    def working_schedules(principal, ranges)
      return [] if ranges.empty?

      span = ranges.map(&:start_date).min..ranges.map(&:end_date).max
      ResourceAllocations::Availability.new(user: principal).working_schedules(span)
    end

    def list_component
      allocations = assignable_allocations
      ResourceAllocations::AssignmentListComponent.new(
        project: @project,
        allocations:,
        visible_work_package_ids: visible_work_package_ids(allocations)
      )
    end

    def assignable_scope
      ResourceAllocation.for_project(@project).needs_principal_assignment
    end

    def assignable_allocations
      assignable_scope.includes(:entity).order(:start_date)
    end

    def visible_work_package_ids(allocations)
      ids = allocations.select { |a| a.entity_type == "WorkPackage" }.map(&:entity_id)
      WorkPackage.visible(current_user).where(id: ids).pluck(:id).to_set
    end

    # Project members the stored filter selects.
    def candidates_for(allocation)
      allocation.candidate_query(project: @project).results.to_a
    end

    def candidate_principal
      User.visible(current_user).in_project(@project).find_by(id: params[:principal_id])
    end

    def find_allocation
      @allocation = assignable_scope.find(params.expect(:id))
    end
  end
end
