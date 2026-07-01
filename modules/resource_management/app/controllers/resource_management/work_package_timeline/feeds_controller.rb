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
  module WorkPackageTimeline
    # Shared setup for the timeline's JSON feeds: locates the planner and view and
    # loads its allocations. Subclasses render the FullCalendar resources and events.
    class FeedsController < BaseController
      menu_item :resource_management

      before_action :find_project_by_project_id
      before_action :authorize
      before_action :find_resource_planner
      before_action :find_view

      private

      def find_resource_planner
        @resource_planner = ResourcePlanner
                              .visible(current_user)
                              .where(project: @project)
                              .with_children
                              .find(params.expect(:resource_planner_id))
      end

      def find_view
        @view = @resource_planner.children.find(params.expect(:view_id))
        render_404 unless @view.is_a?(ResourceWorkPackageTimeline)
      end

      def allocations_by_work_package
        @allocations_by_work_package ||=
          ResourceAllocation.allocated_for_work_packages(@view.work_packages.to_a)
      end
    end
  end
end
