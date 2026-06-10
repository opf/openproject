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

    def new
      respond_with_dialog ResourceAllocations::NewDialogComponent.new(
        project: @project,
        work_package: context_work_package
      )
    end

    def step
      # Pre-select the autocompleter when the dialog was opened from a work package.
      render_allocation_step(ResourceAllocation.new(entity: context_work_package))
    end

    # Recomputes the inline "outside dates" warning whenever a date field
    # changes. Only the banner is replaced — replacing the whole form would
    # make Turbo restore focus to the date input afterwards, reopening its
    # date picker. Uses the EmptyContract so in-progress input never surfaces
    # validation errors while the user types.
    def refresh_form
      allocation = set_attributes(create_params, contract_class: EmptyContract).result
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::ScheduleViolationBannerComponent.new(allocation:)
      )
      respond_with_turbo_streams
    end

    def edit; end

    def create
      # The confirmation step's "Back" button resubmits the carried form values
      # so the editable step can be re-rendered pre-filled.
      return render_back_step if params[:back].present?

      validation = set_attributes(create_params)
      return render_allocation_step(validation.result, status: :unprocessable_entity) if validation.failure?
      return render_warning_step(validation.result) if needs_confirmation?(validation.result)

      persist_allocation
    end

    def update; end

    def destroy; end

    private

    def render_allocation_step(allocation, status: :ok)
      replace_via_turbo_stream(
        component: ResourceAllocations::AllocationStep::FormComponent.new(
          allocation:,
          project: @project,
          allocation_kind:
        ),
        status:
      )
      replace_via_turbo_stream(component: ResourceAllocations::AllocationStep::FooterComponent.new)
      respond_with_turbo_streams(status:)
    end

    def render_warning_step(allocation)
      ranges = overbooked_ranges(allocation)

      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FormComponent.new(
          allocation:,
          project: @project,
          allocation_kind:,
          form_values: submitted_allocation_params,
          filters: params[:filters],
          overbooked_ranges: ranges,
          working_schedules: working_schedules(allocation, ranges)
        )
      )
      replace_via_turbo_stream(
        component: ResourceAllocations::WarningStep::FooterComponent.new
      )
      respond_with_turbo_streams
    end

    def persist_allocation
      call = ResourceAllocations::CreateService
               .new(user: current_user, model: ResourceAllocation.new)
               .call(create_params)

      if call.success?
        render_create_success
      else
        render_allocation_step(call.result, status: :unprocessable_entity)
      end
    end

    def render_back_step
      render_allocation_step(set_attributes(create_params).result)
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

      availability(allocation).overbooking_with(
        start_date: allocation.start_date,
        end_date: allocation.end_date,
        minutes: allocation.allocated_time,
        work_package_id: allocation.entity_id
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

    def render_create_success
      render_success_flash_message_via_turbo_stream(
        message: I18n.t("resource_management.allocate_resource_dialog.success_message")
      )
      close_dialog_via_turbo_stream("##{ResourceAllocations::NewDialogComponent::DIALOG_ID}")
      respond_with_turbo_streams
    end

    def allocation_kind
      params[:allocation_kind].presence || "principal"
    end

    def filter_based_kind?
      allocation_kind == "filter"
    end

    def context_work_package
      return @context_work_package if defined?(@context_work_package)

      @context_work_package = resolve_entity("WorkPackage", params[:work_package_id])
    end

    # Raw, untransformed values to carry through the confirmation step as hidden
    # inputs so a confirmed resubmit recreates exactly what the user entered.
    def submitted_allocation_params
      params
        .fetch(:resource_allocation, {})
        .permit(:principal_id, :filter_name, :start_date, :end_date, :allocated_hours, :entity_type, :entity_id)
        .to_h
    end

    def create_params
      permitted = params
                    .expect(resource_allocation: %i[principal_id filter_name start_date end_date allocated_hours
                                                    entity_type entity_id])
                    .to_h
                    .symbolize_keys

      principal_id = permitted.delete(:principal_id)
      entity = resolve_entity(permitted.delete(:entity_type), permitted.delete(:entity_id))
      permitted.merge(entity:, **resource_params(principal_id))
    end

    # Allow-list the type before constantizing it. Returns nil for an unknown
    # type or unreachable id, letting the entity validations surface the error.
    def resolve_entity(entity_type, entity_id)
      return if entity_id.blank?
      return unless ResourceAllocation::ALLOWED_ENTITY_TYPES.include?(entity_type)

      entity_type.constantize.visible(current_user).where(project: @project).find_by(id: entity_id)
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
  end
end
