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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module My
  class TimeTrackingController < ApplicationController
    include OpTurbo::ComponentStream

    before_action :require_login, :view_mode, :mode, :date

    no_authorization_required!(:index, :refresh)

    menu_item :my_time_tracking

    layout "global"

    helper_method :list_view_component

    def index
      case mode
      when :day then load_time_entries(date)
      when :workweek then load_time_entries(workweek)
      when :week then load_time_entries(date.all_week)
      when :month then load_time_entries(date.all_month)
      end
    end

    def refresh
      if mode == :month # for the month we have the whole week in the table, for the rest it's the day
        load_time_entries(date.all_week)
      else
        load_time_entries(date)
      end

      update_via_turbo_stream(
        component: My::TimeTracking::ListWrapperComponent.new(time_entries: @time_entries, date: date, mode: mode)
      )
      update_via_turbo_stream(
        component: My::TimeTracking::ListStatsComponent.new(time_entries: @time_entries, date: date)
      )

      respond_with_turbo_streams
    end

    private

    def date
      @date ||= parsed_date || current_date
    end

    def workweek
      workdays_normalized = Setting.working_days.map { |day| day % 7 }.sort
      date.all_week(week_start_day).select { |d| workdays_normalized.include?(d.wday) }
    end

    def parsed_date
      if params[:date].present?
        if params[:date] == "today"
          current_date
        else
          begin
            Date.iso8601(params[:date])
          rescue StandardError
            nil
          end
        end
      end
    end

    def default_mode
      if mobile?
        "day"
      else
        "workweek"
      end
    end

    def mode
      @mode ||= begin
        requested = (params[:mode].presence || default_mode).to_sym

        # The mode switcher already hides the month for the stack; this covers a URL
        # asking for one directly.
        requested == :month && view_mode == :stack ? :workweek : requested
      end
    end

    def default_view_mode
      if TimeEntry.can_track_start_and_end_time?
        "calendar"
      else
        "list"
      end
    end

    def view_mode
      @view_mode ||= (params[:view_mode].presence || default_view_mode).to_sym
    end

    def current_date
      Time.zone.today
    end

    def load_time_entries(time_scope)
      @time_entries = My::TimeTracking::EntriesQuery.call(user: User.current, dates: time_scope)
    end

    def list_view_component
      component_class = case view_mode
                        when :list then My::TimeTracking::ListComponent
                        when :stack then My::TimeTracking::StackComponent
                        else My::TimeTracking::CalendarComponent
                        end

      component_class.new(time_entries: @time_entries, mode: mode, date: date)
    end

    def week_start_day
      case Setting.start_of_week
      when 6 then :saturday
      when 7 then :sunday
      else :monday
      end
    end

    def mobile?
      browser.device.mobile?
    end
  end
end
