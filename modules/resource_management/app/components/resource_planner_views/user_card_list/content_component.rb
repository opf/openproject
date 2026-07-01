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
  class ContentComponent < ApplicationComponent
    def initialize(view:, project:, resource_planner:)
      super

      @view = view
      @project = project
      @resource_planner = resource_planner
    end

    private

    def users
      @users ||= @view.results.to_a
    end

    def card_fields
      @view.card_fields
    end

    def remove_path_for(user)
      return nil unless @view.manually_picked?

      helpers.remove_user_project_resource_planner_view_path(
        @project, @resource_planner, @view, user_id: user.id
      )
    end

    def details_path_for(user)
      helpers.project_user_resource_allocations_path(@project, user, resource_planner_id: @resource_planner.id)
    end

    def utilization_for(user)
      return nil unless utilization_window

      ResourceAllocations::Availability
        .new(user:, allocations: booked_allocations.fetch(user.id, []))
        .utilization_ratio(utilization_window)
    end

    def working_schedules_for(user)
      if utilization_window
        ResourceAllocations::Availability.new(user:).working_schedules(utilization_window)
      else
        Array(UserWorkingHours.for_user(user).valid_for_date(Date.current))
      end
    end

    def utilization_window
      return @utilization_window if defined?(@utilization_window)

      from = @resource_planner.start_date
      to = @resource_planner.end_date
      @utilization_window = from && to ? from..to : nil
    end

    def booked_allocations
      @booked_allocations ||=
        if utilization_window
          ResourceAllocation.allocated.for_principal(users).group_by(&:principal_id)
        else
          {}
        end
    end

    def blank_description
      key = @view.manually_picked? ? "manual_description" : "description"
      t("resource_management.user_card_list.blank.#{key}")
    end
  end
end
