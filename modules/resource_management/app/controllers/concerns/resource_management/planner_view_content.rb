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
  # Builds the content component for a resource planner view. Loads the view's
  # work packages and their allocations in one place so the allocation columns
  # (progress bar and members) share a single query rather than each issuing
  # their own. Requires @project and @resource_planner to be set.
  module PlannerViewContent
    def work_package_list_content(view)
      work_packages = view.is_a?(ResourceWorkPackageList) ? view.work_packages.to_a : []
      allocations = ResourceAllocation.allocated_for_work_packages(work_packages)

      ResourcePlannerViews::ContentComponent.new(
        view:,
        project: @project,
        resource_planner: @resource_planner,
        work_packages:,
        allocations:,
        visible_principal_ids: ResourceAllocation.visible_principal_ids(allocations.values.flatten, current_user)
      )
    end
  end
end
