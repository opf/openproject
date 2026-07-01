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

module ResourceAllocations
  module WarningStep
    # Final confirmation step shown before an overbooking allocation is created.
    # The "outside dates" case is surfaced inline in the editable step instead.
    class FormComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include ResourceAllocations::ScheduleSummary

      def initialize(allocation:, project:, allocation_kind:, form_values:, overbooked_ranges: [],
                     working_schedules: [], filters: nil, resource_planner_id: nil)
        super
        @allocation = allocation
        @project = project
        @allocation_kind = allocation_kind
        @form_values = form_values
        @overbooked_ranges = overbooked_ranges
        @working_schedules = working_schedules
        @filters = filters
        @resource_planner_id = resource_planner_id
      end

      def wrapper_key
        ResourceAllocations::NewDialogComponent::BODY_ID
      end

      def overbooked?
        @overbooked_ranges.any?
      end

      private

      # A confirmed resubmit goes back to where the values came from: the
      # update of a persisted allocation or the create flow for a new one.
      def form_url
        if @allocation.persisted?
          project_resource_allocation_path(@project, @allocation, resource_planner_id: @resource_planner_id)
        else
          project_resource_allocations_path(@project, resource_planner_id: @resource_planner_id)
        end
      end

      def form_method
        @allocation.persisted? ? :patch : :post
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

      def capacity_summary(range)
        t(
          "resource_management.allocate_resource_dialog.overbooking.capacity_summary",
          available: format_hours(range.available_minutes),
          scheduled: format_hours(scheduled_minutes(range))
        )
      end

      def scheduled_minutes(range)
        range.items.sum(&:minutes)
      end

      # The forced items whose work package the current user may see, each
      # rendered individually.
      def visible_items(range)
        range.items.select { |item| work_package_for(item) }
      end

      # Work scheduled into the range for work packages the user cannot see,
      # collapsed into a single lump sum so no cross-project subjects leak.
      def hidden_minutes(range)
        range.items.reject { |item| work_package_for(item) }.sum(&:minutes)
      end

      def work_packages_by_id
        @work_packages_by_id ||=
          WorkPackage
            .visible(User.current)
            .where(id: @overbooked_ranges.flat_map(&:work_package_ids).uniq)
            .index_by(&:id)
      end

      def work_package_for(item)
        work_packages_by_id[item.work_package_id]
      end

      def candidate?(item)
        item.id == ResourceAllocations::Availability::CANDIDATE_ID
      end

      def date_range(from_date, to_date)
        "#{format_or_dash(from_date)} - #{format_or_dash(to_date)}"
      end

      def format_or_dash(date)
        date.present? ? helpers.format_date(date) : "—"
      end

      def format_hours(minutes)
        hours = minutes.to_f / 60
        formatted = hours == hours.to_i ? hours.to_i : hours.round(2)
        "#{formatted}h"
      end
    end
  end
end
