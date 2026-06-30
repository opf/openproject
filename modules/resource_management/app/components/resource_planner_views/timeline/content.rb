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

module ResourcePlannerViews
  module Timeline
    # Shared rendering behaviour for the resource-timeline content components.
    # Both the work-package and user timelines mount the same FullCalendar
    # Stimulus controller and differ only in the rows they draw and the feeds
    # behind them. Including components provide those differences through the
    # `timeline_test_selector`, `timeline_empty?` and `timeline_feed_values`
    # hooks; everything else (mounting, common config, allocation linking) is
    # shared here.
    module Content
      extend ActiveSupport::Concern

      # The shared resource-timeline Stimulus controller, registered in setup.ts.
      STIMULUS = "resource-management--resource-timeline"

      # The server dispatches this after an allocation changes; the controller
      # refetches the feeds in place instead of reloading the whole frame.
      RELOAD_EVENT_NAME = "op-dispatched:resource-allocations:changed"

      private

      # The Stimulus controller eagerly reads its calendar target on connect, so
      # it is only mounted when there are rows to draw; an empty view renders a
      # blankslate instead.
      def container_attributes
        attributes = {
          "class" => "op-rm-timeline-view",
          "data-test-selector" => timeline_test_selector
        }
        return attributes if timeline_empty?

        attributes["data-controller"] = STIMULUS
        stimulus_values.each { |key, value| attributes["data-#{STIMULUS}-#{key}-value"] = value }
        attributes
      end

      def stimulus_values
        {
          "locale" => I18n.locale.to_s,
          "first-day" => (Setting.start_of_week.presence || 1).to_i,
          "initial-date" => Date.current.iso8601,
          "initial-view" => Granularity.default_view,
          # The planner's range steers the initial centring (blank when unset).
          "range-start" => @resource_planner.start_date&.iso8601,
          "range-end" => @resource_planner.end_date&.iso8601,
          "new-allocation-url" => new_allocation_url,
          "reload-event-name" => RELOAD_EVENT_NAME
        }.merge(timeline_feed_values)
      end

      def configure_view_path
        helpers.edit_project_resource_planner_view_path(@project, @resource_planner, @view)
      end

      def can_allocate?
        helpers.current_user.allowed_in_project?(:allocate_user_resources, @project)
      end

      # Blank when the user may not allocate (the controller treats a present URL
      # as the permission signal). The timeline appends the selected row and date
      # range as query params.
      def new_allocation_url
        return "" unless can_allocate?

        helpers.new_project_resource_allocation_path(@project)
      end
    end
  end
end
