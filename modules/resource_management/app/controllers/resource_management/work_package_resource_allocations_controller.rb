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
  # Lists the allocations of a single work package in a dialog. Visible to users
  # who may view the work package and hold the `view_resource_planners`
  # permission in its project.
  class WorkPackageResourceAllocationsController < BaseController
    include OpTurbo::ComponentStream

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :find_work_package
    before_action :authorize

    def index
      respond_with_dialog ResourceAllocations::ListDialogComponent.new(
        project: @project,
        work_package: @work_package,
        allocations:,
        visible_principal_ids: ResourceAllocation.visible_principal_ids(allocations, current_user),
        overbooked_ids: ResourceAllocation.overbooked_ids(allocations)
      )
    end

    private

    def allocations
      @allocations ||=
        ResourceAllocation.allocated_for_work_packages([@work_package])[@work_package.id] || []
    end

    # `WorkPackage.visible` enforces the view-work-package permission; a
    # non-visible (or out-of-project) id therefore 404s. The
    # `view_resource_planners` permission is enforced by `authorize`.
    def find_work_package
      @work_package = WorkPackage
                        .visible(current_user)
                        .where(project: @project)
                        .find(params.expect(:work_package_id))
    end
  end
end
