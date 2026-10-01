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

# Values are persisted in UTC as "YYYY-MM-DD HH:MM:SS". That layout compares correctly as a
# string against the timestamps the date and datetime filter operators render, which keeps
# the text-typed custom_values.value column usable for filtering and sorting without casts.
# String input must include a time of day: a date-only value has no unambiguous midnight.
class CustomValue::DateTimeStrategy < CustomValue::FormatStrategy
  include Redmine::I18n

  STORAGE_FORMAT = "%Y-%m-%d %H:%M:%S"
  STORAGE_PATTERN = /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/
  WITH_TIME_PATTERN = /\A\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}/
  # acts_as_customizable stringifies assigned values, so Time and TimeWithZone arrive in their #to_s layout.
  RUBY_TIME_FORMAT = "%Y-%m-%d %H:%M:%S %z"
  RUBY_TIME_PATTERN = /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} (UTC|[+-]\d{4})\z/

  def typed_value
    return if value.blank?

    parse(value)
  end

  def formatted_value
    format_time(typed_value) || value.to_s
  end

  def parse_value(val)
    parse(val)&.strftime(STORAGE_FORMAT) || val
  end

  def validate_type_of_value
    :not_a_datetime unless parse(value)
  end

  private

  def parse(val)
    case val
    when Time, DateTime, ActiveSupport::TimeWithZone
      val.to_time.utc.change(usec: 0)
    when String
      parse_string(val.strip)
    end
  end

  def parse_string(str)
    return unless WITH_TIME_PATTERN.match?(str)

    time = case str
           when STORAGE_PATTERN then ::DateTime.strptime(str, STORAGE_FORMAT).to_time
           when RUBY_TIME_PATTERN then ::DateTime.strptime(str, RUBY_TIME_FORMAT).to_time
           else User.current.time_zone.iso8601(str)
           end

    time.utc.change(usec: 0)
  rescue ArgumentError
    nil
  end
end
