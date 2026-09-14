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
  class ResourceAllocationsController < BaseController
    include OpTurbo::ComponentStream

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_resource_allocation, only: %i[edit update destroy]

    def new
      # Opened from a user's utilization dialog: replace it rather than stack on
      # top. It is reopened (refreshed) after a successful create.
      if reopen_user_allocations_dialog?
        close_dialog_via_turbo_stream(ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent::DIALOG_ID)
      end

      respond_with_dialog ResourceAllocations::NewDialogComponent.new(
        project: @project,
        allocation: prefilled_allocation,
        view: resource_planner_view
      )
    end

    def step
      # Pre-select the autocompleter when the dialog was opened from a work package,
      # and carry any date range picked on the timeline into the new allocation.
      render_allocation_step(
        ResourceAllocation.new(entity: preselected_work_package,
                               start_date: params[:start_date], end_date: params[:end_date])
      )
    end

    # Recomputes the inline "outside dates" warning whenever a date field
    # changes. Only the banner is replaced — replacing the whole form would
    # make Turbo restore focus to the date input afterwards, reopening its
    # date picker. Uses the EmptyContract so in-progress input never surfaces
    # validation errors while the user types.
    def refresh_form
      allocation = set_attributes(allocation_params, contract_class: EmptyContract).result
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::ScheduleViolationBannerComponent.new(allocation:)
      )
      respond_with_turbo_streams
    end

    def edit
      if reopen_user_allocations_dialog?
        close_dialog_via_turbo_stream(ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent::DIALOG_ID)
      end

      respond_with_dialog ResourceAllocations::EditDialogComponent.new(
        project: @project,
        allocation: @resource_allocation,
        view: resource_planner_view
      )
    end

    def create
      # The confirmation step's "Back" button resubmits the carried form values
      # so the editable step can be re-rendered pre-filled.
      return render_back_step if params[:back].present?

      validation = set_attributes(allocation_params)
      return render_allocation_step(validation.result, status: :unprocessable_entity) if validation.failure?
      return render_warning_step(validation.result) if needs_confirmation?(validation.result)

      persist_allocation
    end

    def update
      # The confirmation step's "Back" button resubmits the carried form values
      # so the editable step can be re-rendered pre-filled.
      return render_edit_form(set_update_attributes.result) if params[:back].present?

      validation = set_update_attributes
      return render_edit_form(validation.result, status: :unprocessable_entity) if validation.failure?

      if needs_confirmation?(validation.result)
        return render_warning_step(validation.result,
                                   dialog_id: ResourceAllocations::EditDialogComponent::DIALOG_ID)
      end

      persist_update
    end

    def destroy
      entity = @resource_allocation.entity
      call = ResourceAllocations::DeleteService
               .new(user: current_user, model: @resource_allocation)
               .call

      if call.success?
        render_destroy_success(entity)
      else
        render_error_flash_message_via_turbo_stream(message: call.errors.full_messages.to_sentence)
        respond_with_turbo_streams
      end
    end

    private

    def render_allocation_step(allocation, status: :ok)
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::FormComponent.new(
          allocation:,
          project: @project,
          allocation_kind:,
          view: resource_planner_view
        ),
        status:
      )
      replace_via_turbo_stream(component: ResourceAllocations::AllocationStep::FooterComponent.new)
      respond_with_turbo_streams(status:)
    end

    def render_warning_step(allocation, dialog_id: ResourceAllocations::NewDialogComponent::DIALOG_ID)
      ranges = overbooked_ranges(allocation)

      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FormComponent.new(
          allocation:,
          project: @project,
          allocation_kind:,
          form_values: submitted_allocation_params,
          filters: params[:filters],
          view: resource_planner_view,
          overbooked_ranges: ranges,
          working_schedules: working_schedules(allocation, ranges)
        )
      )
      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FooterComponent.new(dialog_id:)
      )
      respond_with_turbo_streams
    end

    def persist_allocation
      call = ResourceAllocations::CreateService
               .new(user: current_user, model: ResourceAllocation.new)
               .call(allocation_params)

      if call.success?
        render_create_success(call.result)
      else
        render_allocation_step(call.result, status: :unprocessable_entity)
      end
    end

    def render_back_step
      render_allocation_step(set_attributes(allocation_params).result)
    end

    # A final confirmation step is shown only when the allocation would overbook
    # the assigned user. The "outside dates" case is now surfaced as an inline
    # warning in the editable step instead.
    def needs_confirmation?(allocation)
      return false if params[:confirmed].present?

      overbooked_ranges(allocation).any?
    end

    def overbooked_ranges(allocation)
      @overbooked_ranges ||= compute_overbooked_ranges(allocation)
    end

    # Overbooking is a user-level concern, so it is only checked for allocations
    # assigned to a specific user, and only when that user has working time
    # configured (otherwise their capacity is unknown, not zero).
    def compute_overbooked_ranges(allocation)
      return [] unless overbooking_checkable?(allocation)

      # `exclude_id` drops the persisted version of an allocation being edited,
      # so its old booking does not count against the new one.
      availability(allocation).overbooking_with(
        start_date: allocation.start_date,
        end_date: allocation.end_date,
        minutes: allocation.allocated_time,
        work_package_id: allocation.entity_id,
        exclude_id: allocation.id
      )
    end

    def overbooking_checkable?(allocation)
      allocation.principal.present? &&
        allocation.start_date.present? && allocation.end_date.present? &&
        allocation.allocated_time.to_i.positive? &&
        UserWorkingHours.for_user(allocation.principal).exists?
    end

    # The schedule note covers the span of the displayed overbooked ranges so
    # it explains the capacity figures the user actually sees.
    def working_schedules(allocation, ranges)
      return [] if ranges.empty?

      span = ranges.map(&:start_date).min..ranges.map(&:end_date).max
      availability(allocation).working_schedules(span)
    end

    def availability(allocation)
      @availability ||= ResourceAllocations::Availability.new(user: allocation.principal)
    end

    def set_attributes(attributes, contract_class: ResourceAllocations::CreateContract)
      ResourceAllocations::SetAttributesService
        .new(user: current_user, model: ResourceAllocation.new, contract_class:)
        .call(attributes)
    end

    def render_create_success(allocation)
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("resource_management.allocate_resource_dialog.success_message")
      )
      close_dialog_via_turbo_stream(ResourceAllocations::NewDialogComponent::DIALOG_ID)
      refresh_allocations_list(allocation.entity)
      notify_allocation_change(allocation.entity)
      reopen_user_dialog(allocation)
      respond_with_turbo_streams
    end

    def reopen_user_dialog(allocation)
      return unless reopen_user_allocations_dialog?
      return if allocation.principal.nil?

      user = allocation.principal
      allocations = ResourceAllocation.allocated.for_principal(user).includes(:entity).to_a

      dialog_via_turbo_stream(
        component: ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent.new(
          project: @project,
          view: resource_planner_view,
          user:,
          allocations:,
          overbooked_ids: ResourceAllocation.overbooked_ids(allocations)
        )
      )
    end

    # The user-utilization dialog only exists in the user-card view, so the
    # close-and-reopen dance around it is limited to allocations opened there.
    def reopen_user_allocations_dialog?
      resource_planner_view.is_a?(ResourceUserCard)
    end

    # The planner sub-view the dialog was opened from. Its query scopes the
    # autocompleters and its parent planner drives the user-dialog reopen flow.
    # Absent when opened outside a planner (e.g. from a work package's
    # allocations list).
    def resource_planner_view
      return @resource_planner_view if defined?(@resource_planner_view)

      id = params[:resource_planner_view_id]
      @resource_planner_view =
        if id.blank?
          nil
        else
          PersistedView
            .where(parent: ResourcePlanner.visible(current_user).where(project: @project))
            .find_by(id:)
        end
    end

    def set_update_attributes
      ResourceAllocations::SetAttributesService
        .new(user: current_user, model: @resource_allocation, contract_class: ResourceAllocations::UpdateContract)
        .call(allocation_params)
    end

    def persist_update
      call = ResourceAllocations::UpdateService
               .new(user: current_user, model: @resource_allocation)
               .call(allocation_params)

      if call.success?
        render_update_success(call.result)
      else
        render_edit_form(call.result, status: :unprocessable_entity)
      end
    end

    def render_edit_form(allocation, status: :ok)
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::FormComponent.new(
          allocation:,
          project: @project,
          allocation_kind:,
          dialog_id: ResourceAllocations::EditDialogComponent::DIALOG_ID,
          view: resource_planner_view
        ),
        status:
      )
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::FooterComponent.new(
          dialog_id: ResourceAllocations::EditDialogComponent::DIALOG_ID,
          submit_label: I18n.t("resource_management.edit_allocation_dialog.submit"),
          allocation:
        )
      )
      respond_with_turbo_streams(status:)
    end

    def render_update_success(allocation)
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("resource_management.edit_allocation_dialog.success_message")
      )
      close_dialog_via_turbo_stream(ResourceAllocations::EditDialogComponent::DIALOG_ID)
      refresh_allocations_list(allocation.entity)
      notify_allocation_change(allocation.entity)
      reopen_user_dialog(allocation)
      respond_with_turbo_streams
    end

    def render_destroy_success(entity)
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("resource_management.work_package_allocations_dialog.delete_success")
      )
      # Closes the edit dialog when the delete was triggered from it; a harmless
      # no-op when deleting from a list row, where the dialog is not open.
      close_dialog_via_turbo_stream(ResourceAllocations::EditDialogComponent::DIALOG_ID)
      refresh_allocations_list(entity)
      notify_allocation_change(entity)
      respond_with_turbo_streams
    end

    # The stream is a no-op on the client when the work package's allocations
    # dialog is not open.
    def refresh_allocations_list(work_package)
      return unless work_package.is_a?(WorkPackage)

      allocations = ResourceAllocation.allocated_for_work_packages([work_package])[work_package.id] || []
      replace_via_turbo_stream(
        component: ResourceAllocations::ListComponent.new(
          project: @project,
          work_package:,
          allocations:,
          visible_principal_ids: ResourceAllocation.visible_principal_ids(allocations, current_user),
          overbooked_ids: ResourceAllocation.overbooked_ids(allocations)
        )
      )
    end

    # The controller stays unaware of which view (if any) is on screen: a
    # resource planner table open on the page reloads the affected work package
    # in response, and the stream is a harmless no-op when nothing listens.
    def notify_allocation_change(entity)
      return unless entity.is_a?(WorkPackage)

      dispatch_event_via_turbo_stream("op-dispatched:resource-allocations:changed", detail: { work_package_id: entity.id })
    end

    def allocation_kind
      params[:allocation_kind].presence || "principal"
    end

    def filter_based_kind?
      allocation_kind == "filter"
    end

    # Raw, untransformed values to carry through the confirmation step as hidden
    # inputs so a confirmed resubmit recreates exactly what the user entered.
    def submitted_allocation_params
      params
        .fetch(:resource_allocation, {})
        .permit(:principal_id, :filter_name, :date_range, :allocated_hours, :entity_type, :entity_id)
        .to_h
    end

    # Only allocations of work packages reachable by the current user within
    # the project may be touched; anything else 404s.
    def find_resource_allocation
      @resource_allocation = ResourceAllocation
                               .where(entity_type: "WorkPackage",
                                      entity_id: WorkPackage.visible(current_user).where(project: @project))
                               .find(params.expect(:id))
    end

    def allocation_params
      permitted = params
                    .expect(resource_allocation: %i[principal_id filter_name date_range allocated_hours
                                                    entity_type entity_id])
                    .to_h
                    .symbolize_keys

      principal_id = permitted.delete(:principal_id)
      entity = resolve_visible_entity(permitted.delete(:entity_type), permitted.delete(:entity_id))
      permitted.merge(entity:, **resource_params(principal_id))
    end

    def resource_params(principal_id)
      if filter_based_kind?
        {
          principal_explicit: false,
          principal: nil,
          user_filter: parsed_user_filter
        }
      else
        {
          principal_explicit: true,
          principal: User.visible.in_project(@project).find_by(id: principal_id),
          filter_name: nil,
          user_filter: []
        }
      end
    end

    # `user_filter` serializes UserQuery filter objects, so convert the
    # FilterForm's JSON payload into them.
    def parsed_user_filter
      return [] if params[:filters].blank?

      query = UserQuery.new
      ::Queries::ParamsParser.parse(filters: params[:filters])
                             .fetch(:filters, [])
                             .each { |f| query.where(f[:attribute], f[:operator], f[:values]) }
      query.filters
    end

    def preselected_work_package
      return @preselected_work_package if defined?(@preselected_work_package)

      @preselected_work_package = resolve_visible_entity("WorkPackage", params[:work_package_id])
    end

    def preselected_user
      return @preselected_user if defined?(@preselected_user)

      @preselected_user = User.visible(current_user).in_project(@project).find_by(id: params[:principal_id])
    end

    # A pre-selected user lets the dialog skip the kind step and open directly on
    # the allocation form.
    def prefilled_allocation
      ResourceAllocation.new(
        principal: preselected_user,
        principal_explicit: preselected_user.present?,
        entity: preselected_work_package,
        start_date: params[:start_date],
        end_date: params[:end_date]
      )
    end
  end
end
