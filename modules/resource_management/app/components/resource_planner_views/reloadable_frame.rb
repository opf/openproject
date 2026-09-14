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
  # Wraps a content component in a reloadable turbo frame so allocation changes
  # made in the dialogs refresh the content in place. The frame has no `src`, so
  # it is not fetched on load — it just holds the server-rendered content. The
  # `reload-frame-on-event` controller points its `src` at the same view and
  # morphs it in when an allocation of any listed work package changes.
  #
  # Timelines deliberately do not use this: their FullCalendar controller refetches
  # its feeds in place on the same event, so they opt out of the frame-level reload
  # to avoid tearing down and re-instantiating the calendar.
  module ReloadableFrame
    FRAME_ID = "resource-planner-view-content"
    RELOAD_EVENT_NAME = "op-dispatched:resource-allocations:changed"

    private

    def reloadable_content_frame(&)
      helpers.turbo_frame_tag(FRAME_ID, refresh: :morph, data: reload_frame_data, &)
    end

    def reload_frame_data
      {
        controller: "reload-frame-on-event",
        "reload-frame-on-event-event-name-value": RELOAD_EVENT_NAME,
        "reload-frame-on-event-url-value": helpers.project_resource_planner_view_path(
          @project, @resource_planner, @view
        )
      }
    end
  end
end
