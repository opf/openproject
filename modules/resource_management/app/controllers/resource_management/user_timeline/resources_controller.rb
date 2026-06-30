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

module ResourceManagement
  module UserTimeline
    # Feeds the FullCalendar resources (rows): one per user in the view.
    class ResourcesController < FeedsController
      def index
        overbooked = overbooked_principal_ids
        scheduled = scheduled_principal_ids
        resources = users.map.with_index do |user, index|
          {
            id: user.id,
            title: user.name,
            order: index,
            extendedProps: {
              html: render_cell(user, overbooked: overbooked.include?(user.id),
                                      schedule_missing: scheduled.exclude?(user.id))
            }
          }
        end

        render json: { resources: }
      end

      private

      # The ids of the users who are overbooked somewhere within their booked
      # allocations, so the resource cell can flag them with a warning icon.
      def overbooked_principal_ids
        allocations = allocations_by_principal.values.flatten
        overbooked = ResourceAllocation.overbooked_ids(allocations)

        allocations.select { |allocation| overbooked.include?(allocation.id) }
                   .to_set(&:principal_id)
      end

      # The ids of the users who have a work schedule set up, so the resource
      # cell can flag those who do not. Fetched in a single query.
      def scheduled_principal_ids
        UserWorkingHours.for_user(users).distinct.pluck(:user_id).to_set
      end

      def render_cell(user, overbooked:, schedule_missing:)
        ResourcePlannerViews::UserTimeline::ResourceCellComponent
          .new(user:, overbooked:, schedule_missing:,
               project: @project, resource_planner: @resource_planner, view: @view)
          .render_in(view_context)
      end
    end
  end
end
