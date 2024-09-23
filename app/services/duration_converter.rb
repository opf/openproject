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

class DurationConverter
  UNIT_ABBREVIATION_MAP = {
    "seconds" => "seconds",
    "second" => "seconds",
    "secs" => "seconds",
    "sec" => "seconds",
    "s" => "seconds",
    "minutes" => "minutes",
    "minute" => "minutes",
    "mins" => "minutes",
    "min" => "minutes",
    "m" => "minutes",
    "hours" => "hours",
    "hour" => "hours",
    "hrs" => "hours",
    "hr" => "hours",
    "h" => "hours",
    "days" => "days",
    "day" => "days",
    "dy" => "days",
    "d" => "days",
    "weeks" => "weeks",
    "week" => "weeks",
    "wks" => "weeks",
    "wk" => "weeks",
    "w" => "weeks",
    "months" => "months",
    "mo" => "months",
    "mos" => "months",
    "month" => "months",
    "years" => "years",
    "year" => "years",
    "yrs" => "years",
    "yr" => "years",
    "y" => "years"
  }.freeze

  NEXT_UNIT_MAP = {
    "years" => "months",
    "months" => "weeks",
    "weeks" => "days",
    "days" => "hours",
    "hours" => "minutes",
    "minutes" => "seconds"
  }.freeze

  class << self
    def parse(duration_string)
      return nil if duration_string.blank?

      do_parse(duration_string)
    end

    def valid?(duration)
      case duration
      when String
        duration.blank? || parseable?(duration)
      when Numeric
        duration >= 0
      when nil
        true
      else
        false
      end
    rescue ChronicDuration::DurationParseError
      false
    end

    def output(duration_in_hours)
      return duration_in_hours if duration_in_hours.nil?

      seconds = (duration_in_hours * 3600).to_i

      # :days_and_hours format return "0h" when parsing 0.
      ChronicDuration.output(seconds,
                             format:,
                             **duration_length_options)
    end

    private

    def parseable?(duration_string)
      if number = Integer(duration_string, 10, exception: false) || Float(duration_string, exception: false)
        number >= 0
      else
        begin
          do_parse(duration_string)
          true
        rescue ChronicDuration::DurationParseError
          false
        end
      end
    end

    def do_parse(duration_string)
      # Assume the next logical unit to allow users to write
      # durations such as "2h 1" assuming "1" is "1 minute"
      last_unit_in_string = duration_string.scan(/[a-zA-Z]+/)
                                           .last
      default_unit = if last_unit_in_string
                       last_unit_in_string
                         .then { |last_unit| UNIT_ABBREVIATION_MAP[last_unit.downcase] }
                         .then { |last_unit| NEXT_UNIT_MAP[last_unit] }
                     else
                       "hours"
                     end

      ChronicDuration.parse(duration_string,
                            keep_zero: true,
                            default_unit:,
                            raise_exceptions: true,
                            **duration_length_options) / 3600.to_f
    end

    def format
      Setting.duration_format == "days_and_hours" ? :days_and_hours : :hours_only
    end

    def duration_length_options
      { hours_per_day: Setting.hours_per_day,
        days_per_month: Setting.days_per_month }
    end
  end
end
