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

module ResourcePlannerViews::UserCardList
  class UserAllocationsDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include ResourceManagement::PlannerRoutes

    DIALOG_ID = "user-allocations-dialog"

    def initialize(project:, view:, user:, allocations:, timeframe: nil, overbooked_ids: Set.new)
      super

      @project = project
      @view = view
      @user = user
      @allocations = allocations
      @timeframe = timeframe
      @overbooked_ids = overbooked_ids
    end

    private

    attr_reader :project, :view, :user, :allocations, :timeframe, :overbooked_ids

    def title
      I18n.t("resource_management.user_allocations_dialog.title")
    end

    def availability
      @availability ||= ResourceAllocations::Availability.new(user:, allocations:)
    end

    def utilization
      return @utilization if defined?(@utilization)

      @utilization = timeframe && availability.utilization_ratio(timeframe)
    end

    def utilization?
      !utilization.nil?
    end

    def utilization_label
      helpers.number_to_percentage(utilization, precision: 0)
    end

    def timeframe_label
      t("resource_management.timeframe.full",
        start: helpers.format_date(timeframe.begin),
        end: helpers.format_date(timeframe.end))
    end

    def capacity_known?
      timeframe.present? && capacity_minutes.positive?
    end

    def capacity_label
      t("resource_management.user_allocations_dialog.total_time",
        hours: DurationConverter.output(capacity_minutes / 60.0))
    end

    def capacity_minutes
      @capacity_minutes ||= availability.capacity_minutes_within(timeframe)
    end

    def blank_label
      key = timeframe ? "blank_in_timeframe" : "blank"

      t("resource_management.user_allocations_dialog.#{key}")
    end

    def visible?(allocation)
      work_package_for(allocation).present?
    end

    def hidden_label
      t("resource_management.user_allocations_dialog.hidden_work_package")
    end

    # A global dialog spans projects, and inside a project the allocations
    # reaching outside it are the ones worth naming.
    def show_project?(allocation)
      work_package_project = work_package_for(allocation)&.project

      work_package_project.present? && work_package_project != project
    end

    # Every allocation the utilization above is computed from gets its own row, so
    # the lookup is bounded by what the viewer may see and nothing else.
    def work_packages_by_id
      @work_packages_by_id ||=
        WorkPackage
          .visible(User.current)
          .where(id: allocations.map(&:entity_id).uniq)
          .includes(:project)
          .index_by(&:id)
    end

    def work_package_for(allocation)
      work_packages_by_id[allocation.entity_id]
    end

    def overbooked?(allocation)
      overbooked_ids.include?(allocation.id)
    end

    def duration(allocation)
      DurationConverter.output(allocation.allocated_hours)
    end

    def date_range(allocation)
      "#{helpers.format_date(allocation.start_date)} - #{helpers.format_date(allocation.end_date)}"
    end

    # The permission lives on the project of the allocated work package, which on
    # a global planner differs from row to row.
    def editable?(allocation)
      allocation_project = work_package_for(allocation)&.project
      return false if allocation_project.nil?

      @editable ||= {}
      @editable.fetch(allocation_project.id) do
        @editable[allocation_project.id] =
          User.current.allowed_in_project?(:allocate_user_resources, allocation_project)
      end
    end

    def overbooked_message
      t("resource_management.work_package_allocations_dialog.overbooked")
    end

    def overbooked_icon_id(allocation)
      "user-allocation-overbooked-#{allocation.id}"
    end

    def allocate_work_package_path
      new_allocation_path(project, principal_id: user.id, resource_planner_view_id: view.id)
    end

    def edit_path_for(allocation)
      edit_allocation_path(project, allocation, resource_planner_view_id: view.id)
    end

    # The view is carried along so the destroy response knows to re-render this
    # dialog, which stays open behind the confirmation.
    def delete_path_for(allocation)
      allocation_path(project, allocation, resource_planner_view_id: view.id)
    end
  end
end
