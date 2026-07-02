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

    DIALOG_ID = "user-allocations-dialog"

    def initialize(project:, resource_planner:, user:, allocations:, overbooked_ids: Set.new)
      super

      @project = project
      @resource_planner = resource_planner
      @user = user
      @allocations = allocations
      @overbooked_ids = overbooked_ids
    end

    private

    attr_reader :project, :resource_planner, :user, :allocations, :overbooked_ids

    def title
      I18n.t("resource_management.user_allocations_dialog.title")
    end

    def utilization
      return @utilization if defined?(@utilization)

      @utilization = utilization_window &&
                     ResourceAllocations::Availability.new(user:, allocations:).utilization_ratio(utilization_window)
    end

    def utilization?
      !utilization.nil?
    end

    def utilization_label
      helpers.number_to_percentage(utilization, precision: 0)
    end

    def utilization_window
      return @utilization_window if defined?(@utilization_window)

      from = resource_planner.start_date
      to = resource_planner.end_date
      @utilization_window = from && to ? from..to : nil
    end

    def visible_allocations
      allocations.select { |allocation| work_package_for(allocation) }
    end

    def hidden_allocations
      allocations.reject { |allocation| work_package_for(allocation) }
    end

    def hidden_count
      hidden_allocations.size
    end

    def hidden_duration
      DurationConverter.output(hidden_allocations.sum(&:allocated_hours))
    end

    def work_packages_by_id
      @work_packages_by_id ||=
        WorkPackage
          .visible(User.current)
          .where(project:, id: allocations.map(&:entity_id).uniq)
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

    def editable?
      return @editable if defined?(@editable)

      @editable = User.current.allowed_in_project?(:allocate_user_resources, project)
    end

    def overbooked_message
      t("resource_management.work_package_allocations_dialog.overbooked")
    end

    def overbooked_icon_id(allocation)
      "user-allocation-overbooked-#{allocation.id}"
    end

    def allocate_work_package_path
      new_project_resource_allocation_path(project, principal_id: user.id, resource_planner_id: resource_planner.id)
    end

    def edit_allocation_path(allocation)
      edit_project_resource_allocation_path(project, allocation, resource_planner_id: resource_planner.id)
    end

    def delete_allocation_path(allocation)
      project_resource_allocation_path(project, allocation)
    end
  end
end
