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
  class UserResourceAllocationsController < BaseController
    include OpTurbo::ComponentStream

    menu_item :resource_management

    before_action :find_project_by_project_id
    before_action :find_resource_planner
    before_action :find_user
    before_action :authorize

    def index
      respond_with_dialog ResourcePlannerViews::UserCardList::UserAllocationsDialogComponent.new(
        project: @project,
        resource_planner: @resource_planner,
        user: @user,
        allocations:,
        overbooked_ids: ResourceAllocation.overbooked_ids(allocations)
      )
    end

    private

    def allocations
      @allocations ||=
        ResourceAllocation
          .allocated
          .for_principal(@user)
          .includes(:entity)
          .to_a
    end

    def find_resource_planner
      @resource_planner = ResourcePlanner
                            .visible(current_user)
                            .where(project: @project)
                            .find(params.expect(:resource_planner_id))
    end

    def find_user
      @user = User.visible(current_user).find(params.expect(:user_id))
    end
  end
end
