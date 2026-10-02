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
  module Work
    class ListComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers
      include My::WorkHelper

      options time_entries: [],
              allocations: [],
              entries: :all,
              mode: :week,
              date: Date.current

      private

      def wrapper_data
        {
          "controller" => "my--work",
          "my--work-mode-value" => mode,
          "my--work-view-mode-value" => "list",
          "my--work-entries-value" => entries
        }
      end

      def range
        case mode
        when :day then [date]
        when :week then week_days(date)
        when :workweek then workweek_days(date)
        when :month then month_days
        end
      end

      def grouped_time_entries
        @grouped_time_entries ||= group_by_section(time_entries, &:spent_on)
      end

      def grouped_allocations
        @grouped_allocations ||= group_by_section(allocations) { |event| event.scheduled_entry.allocated_on }
      end

      def group_by_section(items)
        items
          .group_by { |item| section_for(yield(item)) }
          .tap do |hash|
            hash.default_proc = ->(h, k) { h[k] = [] }
          end
      end

      def section_for(day)
        mode == :month ? day.beginning_of_week(week_start_day) : day
      end

      def date_title(date)
        if mode == :month
          week_date_range(date)
        else
          I18n.l(date, format: "%A %d")
        end
      end

      def month_days
        date.all_month.map { |day| day.beginning_of_week(week_start_day) }.uniq
      end

      def week_start_day
        OpenProject::Internationalization::Date.beginning_of_week
      end

      def collapsed?(date) # rubocop:disable Metrics/AbcSize
        return false if mode == :day
        return false if mode.in?(%i[week workweek]) && range.exclude?(Date.current)
        return false if mode == :month && range.exclude?(Date.current.beginning_of_week)

        if mode == :month
          Date.current.cweek != date.cweek
        else
          !date.today?
        end
      end

      def date_caption(date)
        if mode == :month
          if Date.current.beginning_of_week(week_start_day) == date
            t(:label_this_week)
          elsif 1.week.ago.beginning_of_week(week_start_day) == date
            t(:label_last_week)
          end
        elsif date.today?
          t(:label_today)
        elsif date.yesterday?
          t(:label_yesterday)
        end
      end
    end
  end
end
