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

module DemoData
  # Seeds working hours (weekly schedules) and vacations (non-working times) for the demo users,
  # deliberately covering all cases: users without a schedule, users with a single schedule, and
  # users whose schedule changes over time (e.g. reduced hours over the summer).
  class WorkingTimeSeeder < Seeder
    # Working hours are stored as minutes per weekday.
    FULL_TIME        = { monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480, saturday: 0, sunday: 0 }.freeze
    SUMMER_HALF_DAYS = { monday: 240, tuesday: 240, wednesday: 240, thursday: 240, friday: 240, saturday: 0, sunday: 0 }.freeze
    THREE_DAY_WEEK   = { monday: 480, tuesday: 480, wednesday: 480, thursday: 0,   friday: 0,   saturday: 0, sunday: 0 }.freeze
    FOUR_DAY_WEEK    = { monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 0,   saturday: 0, sunday: 0 }.freeze
    VERY_LOW_HOURS   = { monday: 120, tuesday: 0,   wednesday: 120, thursday: 0,   friday: 120, saturday: 0, sunday: 0 }.freeze

    # Schedules per user reference. Each entry is [minutes, valid_from, availability_factor], where
    # valid_from is [month, day] within the current year or nil for the start of the year. Multiple
    # entries model a schedule that changes over time. Connie Comms, Carl Content, Polly PR and
    # Adam Admin are intentionally absent to cover the "no schedule" case.
    SCHEDULES = {
      user__marko_marketing: [[FULL_TIME, nil, 100]],
      user__wanda_web: [[FULL_TIME, nil, 100]],
      user__evan_events: [[FULL_TIME, nil, 100]],
      user__ivan_it: [[FULL_TIME, nil, 80]],               # full-time hours, 80% available
      user__petra_press: [[THREE_DAY_WEEK, nil, 100]],     # part-time three-day week
      user__fritz_finance: [[VERY_LOW_HOURS, nil, 100]],   # part-time, very low hours (6h/week)
      user__dora_design: [                                 # half days over the summer, full otherwise
        [FULL_TIME, nil, 100],
        [SUMMER_HALF_DAYS, [6, 1], 100],
        [FULL_TIME, [9, 1], 100]
      ],
      user__olga_ops: [                                    # switched to a four-day week mid-year
        [FULL_TIME, nil, 100],
        [FOUR_DAY_WEEK, [7, 1], 100]
      ]
    }.freeze

    # Vacations per user reference as [[start_month, start_day], [end_month, end_day]] within the
    # current year. Polly PR has no schedule but still takes a vacation.
    VACATIONS = {
      user__marko_marketing: [[7, 14], [7, 25]],
      user__wanda_web: [[12, 23], [12, 31]],
      user__evan_events: [[4, 1], [4, 5]],
      user__fritz_finance: [[8, 4], [8, 15]],
      user__dora_design: [[12, 23], [12, 31]],
      user__polly_pr: [[5, 19], [5, 23]]
    }.freeze

    def seed_data!
      print_status "    ↳ Creating working hours and vacations" do
        seed_schedules
        seed_vacations
      end
    end

    def applicable?
      UserWorkingHours.none? && UserNonWorkingTime.none?
    end

    private

    def seed_schedules
      SCHEDULES.each do |reference, entries|
        entries.each do |minutes, month_day, availability_factor|
          valid_from = month_day ? Date.new(year, *month_day) : year_start
          working_hours(reference, minutes, valid_from:, availability_factor:)
        end
      end
    end

    def seed_vacations
      VACATIONS.each do |reference, ((start_month, start_day), (end_month, end_day))|
        vacation(reference, Date.new(year, start_month, start_day), Date.new(year, end_month, end_day))
      end
    end

    def working_hours(reference, minutes, valid_from:, availability_factor: 100)
      user = find_user(reference)
      return unless user

      UserWorkingHours.create!(user:, valid_from:, availability_factor:, **minutes)
    end

    def vacation(reference, start_date, end_date)
      user = find_user(reference)
      return unless user

      UserNonWorkingTime.create!(user:, start_date:, end_date:)
    end

    def find_user(reference)
      seed_data.find_reference(reference, default: nil)
    end

    def year
      @year ||= Date.current.year
    end

    def year_start
      @year_start ||= Date.current.beginning_of_year
    end
  end
end
