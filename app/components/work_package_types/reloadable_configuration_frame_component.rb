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

module WorkPackageTypes
  # Wraps a configuration editor in a turbo frame that reloads whenever the
  # type's configuration changes out-of-band — a copy from another type, a
  # reuse-mode switch. The frame has no `src`, so it is not fetched on load —
  # it just holds the server-rendered content until the change event points it
  # at +reload_url+, which must render the frame again (the tab's edit page or
  # the wizard step).
  class ReloadableConfigurationFrameComponent < ApplicationComponent
    FRAME_ID = "type-configuration-frame"
    RELOAD_EVENT_NAME = "op-dispatched:types:configuration-changed"

    def initialize(reload_url:)
      super()

      @reload_url = reload_url
    end

    def call
      helpers.turbo_frame_tag(FRAME_ID, class: "op-reloadable-configuration-frame", data: frame_data) { content }
    end

    private

    def frame_data
      {
        controller: "reload-frame-on-event",
        "reload-frame-on-event-event-name-value": RELOAD_EVENT_NAME,
        "reload-frame-on-event-url-value": @reload_url
      }
    end
  end
end
