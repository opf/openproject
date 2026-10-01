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
    class SubHeaderComponent < ApplicationComponent
      include My::TimeTrackingHelper

      options :date, :mode, :view_mode

      def title
        case mode
        when :day
          I18n.l(date, format: :long)
        when :week
          week_date_range(date)
        when :workweek
          workweek_date_range(date)
        when :month
          I18n.l(date, format: "%B %Y")
        end
      end

      # Overridden where the sub header drives something other than the full page, such as
      # the my page widget.
      def path_for(date:, mode: self.mode)
        my_time_tracking_path(date:, view_mode:, mode:)
      end

      def mode_switcher
        My::TimeTracking::ModeSwitcherComponent.new(
          current_mode: mode,
          view_mode:,
          path_builder: ->(for_mode) { path_for(date:, mode: for_mode) },
          link_data:
        )
      end

      def link_data
        {}
      end

      def today_href
        path_for(date: "today")
      end

      def previous_attrs
        { href: path_for(date: date - step), aria: { label: I18n.t(:"label_previous_#{mode}") } }
      end

      def next_attrs
        { href: path_for(date: date + step), aria: { label: I18n.t(:"label_next_#{mode}") } }
      end

      def step
        case mode
        when :day then 1.day
        when :month then 1.month
        else 1.week
        end
      end

      def can_create_time_entry?
        User.current.allowed_in_any_work_package?(:log_own_time) || User.current.allowed_in_any_project?(:log_time)
      end
    end
  end
end
