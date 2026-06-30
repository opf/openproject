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

module ResourcePlannerViews::UserTimeline
  # Renders the user timeline: the toolbar plus one swimlane per selected user.
  # The interactive FullCalendar timeline is mounted into the swimlane area in a
  # later step; for now the swimlanes are rendered server-side.
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

    def blank_description
      key = @view.manually_picked? ? "manual_description" : "description"
      t("resource_management.user_timeline.blank.#{key}")
    end

    def add_user_path
      helpers.new_user_project_resource_planner_view_path(@project, @resource_planner, @view)
    end

    def configure_view_path
      helpers.edit_project_resource_planner_view_path(@project, @resource_planner, @view)
    end
  end
end
