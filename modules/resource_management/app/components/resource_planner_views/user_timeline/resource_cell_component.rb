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
  module UserTimeline
    # The user row shown in the timeline's resource (left) column. Rendered
    # server-side so it stays consistent with the user card view. Flags users who
    # are over-allocated somewhere in their bookings with a warning icon.
    class ResourceCellComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include AvatarHelper

      def initialize(user:, overbooked: false, project: nil, resource_planner: nil, view: nil)
        super
        @user = user
        @overbooked = overbooked
        @project = project
        @resource_planner = resource_planner
        @view = view
      end

      private

      attr_reader :user

      def overbooked? = @overbooked

      def overbooked_label
        t("resource_management.user_timeline.overbooked")
      end
    end
  end
end
