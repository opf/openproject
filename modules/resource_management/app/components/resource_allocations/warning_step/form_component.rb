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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ResourceAllocations
  module WarningStep
    # Final confirmation step shown before an overbooking allocation is created.
    # The "outside dates" case is surfaced inline in the editable step instead.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include ResourceAllocations::ScheduleSummary
      include ResourceManagement::PlannerRoutes

      # `body_id`/`form_id`/`footer ids default to the allocate wizard's so the
      # create and edit flows are unchanged. The Staffing flow hosts the same
      # confirmation in its own dialog by passing its ids, a custom `form_url`
      # and the plain `hidden_fields` to carry through a confirmed resubmit.
      def initialize(allocation:, project:, form_values:, overbooking: nil,
                     working_schedules: [], filters: nil, view: nil,
                     body_id: ResourceAllocations::NewDialogComponent::BODY_ID,
                     form_id: ResourceAllocations::NewDialogComponent::FORM_ID,
                     form_url: nil, form_method: nil, hidden_fields: nil)
        super
        @allocation = allocation
        @project = project
        @form_values = form_values
        @overbooking = overbooking
        @working_schedules = working_schedules
        @filters = filters
        @view = view
        @body_id = body_id
        @form_id = form_id
        @form_url = form_url
        @form_method = form_method
        @hidden_fields = hidden_fields
      end

      def wrapper_key
        @body_id
      end

      def overbooked?
        @overbooking&.overbooked? || false
      end

      private

      attr_reader :form_id, :hidden_fields

      # A confirmed resubmit goes back to where the values came from: the
      # update of a persisted allocation or the create flow for a new one.
      def form_url
        return @form_url if @form_url

        if @allocation.persisted?
          allocation_path(@project, @allocation, resource_planner_view_id: @view&.id)
        else
          allocations_path(@project, resource_planner_view_id: @view&.id)
        end
      end

      def form_method
        @form_method || (@allocation.persisted? ? :patch : :post)
      end

      def overbooking_heading
        t("resource_management.allocate_resource_dialog.overbooking.title")
      end

      def overbooking_description
        t("resource_management.allocate_resource_dialog.overbooking.description", user: @allocation.principal.name)
      end

      def working_schedule?
        @working_schedules.any?
      end

      # One sentence chaining each schedule effective during the overbooked
      # span, e.g. "This user works Mon-Fri 8h until 03/31/2026, then Mon-Thu
      # 6h (80% available for project work)."
      def schedule_note
        schedule_sentence(@working_schedules)
      end

      def overtime_summary
        t(
          "resource_management.allocate_resource_dialog.overbooking.overtime_summary_html",
          hours: format_hours(@allocation.allocated_time),
          start_date: format_date(@allocation.start_date),
          end_date: format_date(@allocation.end_date),
          overtime: format_hours(@overbooking.overtime_minutes),
          overtime_start_date: format_date(@overbooking.period.begin),
          overtime_end_date: format_date(@overbooking.period.end)
        )
      end

      def unplannable?
        @overbooking.unplannable
      end

      def unplannable_note
        t(
          "resource_management.allocate_resource_dialog.overbooking.unplannable",
          user: @allocation.principal.name,
          start_date: format_date(@allocation.start_date),
          end_date: format_date(@allocation.end_date)
        )
      end

      def format_hours(minutes)
        hours = minutes.to_f / 60
        formatted = hours == hours.to_i ? hours.to_i : hours.round(2)
        "#{formatted}h"
      end
    end
  end
end
