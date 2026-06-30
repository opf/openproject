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
  # The container the shared resource-timeline FullCalendar controller mounts
  # into, rendering one swimlane per user. Bulk data comes from the feed
  # endpoints; only small config travels inline. Mirrors
  # WorkPackageTimeline::ContentComponent with the user feeds and a user-row
  # selection param.
  class ContentComponent < ApplicationComponent
    include ResourcePlannerViews::Timeline::Content

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

    def timeline_test_selector
      "resource-user-timeline"
    end

    def timeline_empty?
      users.empty?
    end

    def timeline_feed_values
      {
        "resources-url" => helpers.project_resource_planner_view_user_timeline_resources_path(
          @project, @resource_planner, @view, format: :json
        ),
        "events-url" => helpers.project_resource_planner_view_user_timeline_events_path(
          @project, @resource_planner, @view, format: :json
        ),
        # A date-range selection on a user row pre-fills that user (principal) on
        # the new-allocation dialog.
        "selection-param" => "principal_id"
      }
    end

    def blank_description
      key = @view.manually_picked? ? "manual_description" : "description"
      t("resource_management.user_timeline.blank.#{key}")
    end

    def add_user_path
      helpers.new_user_project_resource_planner_view_path(@project, @resource_planner, @view)
    end
  end
end
