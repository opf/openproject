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
        when :week, :workweek
          week_date_range(date)
        when :month
          I18n.l(date, format: "%B %Y")
        end
      end

      def today_href
        my_time_tracking_path(date: "today", view_mode:, mode:)
      end

      def previous_attrs # rubocop:disable Metrics/AbcSize
        case mode
        when :day
          { href: my_time_tracking_path(date: date - 1.day, view_mode:, mode:),
            aria: { label: I18n.t(:label_previous_day) } }
        when :workweek
          { href: my_time_tracking_path(date: date - 1.week, view_mode:, mode:),
            aria: { label: I18n.t(:label_previous_workweek) } }
        when :week
          { href: my_time_tracking_path(date: date - 1.week, view_mode:, mode:),
            aria: { label: I18n.t(:label_previous_week) } }
        when :month
          { href: my_time_tracking_path(date: date - 1.month, view_mode:, mode:),
            aria: { label: I18n.t(:label_previous_month) } }
        end
      end

      def next_attrs # rubocop:disable Metrics/AbcSize
        case mode
        when :day
          { href: my_time_tracking_path(date: date + 1.day, view_mode:, mode:),
            aria: { label: I18n.t(:label_next_day) } }
        when :workweek
          { href: my_time_tracking_path(date: date + 1.week, view_mode:, mode:),
            aria: { label: I18n.t(:label_next_workweek) } }
        when :week
          { href: my_time_tracking_path(date: date + 1.week, view_mode:, mode:),
            aria: { label: I18n.t(:label_next_week) } }
        when :month
          { href: my_time_tracking_path(date: date + 1.month, view_mode:, mode:),
            aria: { label: I18n.t(:label_next_month) } }
        end
      end

      def can_create_time_entry?
        User.current.allowed_in_any_work_package?(:log_own_time) || User.current.allowed_in_any_project?(:log_time)
      end
    end
  end
end
