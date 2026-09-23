# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module TimeTracking
    # Holds a my time tracking view so that stepping through dates, switching the mode and
    # switching the view replace only this frame.
    class ViewFrameComponent < ApplicationComponent
      FRAME_ID = "my-time-tracking-view"

      def call
        helpers.turbo_frame_tag(FRAME_ID, data: { turbo_action: "advance" }) do
          parts = [content]
          if helpers.turbo_frame_request?
            parts << helpers.turbo_stream.set_title(title: helpers.page_title(*helpers.html_title_parts))
          end
          safe_join(parts)
        end
      end
    end
  end
end
