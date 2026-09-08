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

class CustomValue::DateTimeStrategy < CustomValue::FormatStrategy
  include Redmine::I18n

  CANONICAL_FORMAT = "%Y-%m-%d %H:%M:%S"
  CANONICAL_REGEX = /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/

  def typed_value
    return if value.blank?

    DateTime.strptime(value, CANONICAL_FORMAT)
  rescue Date::Error
    nil
  end

  def formatted_value
    format_time(typed_value) || value.to_s
  end

  def parse_value(val)
    super(normalize_to_utc(val) || val)
  end

  def validate_type_of_value
    return nil if value.is_a?(Time) || value.is_a?(Date)

    begin
      DateTime.strptime(value, CANONICAL_FORMAT)
      nil
    rescue StandardError
      :not_a_datetime
    end
  end

  private

  def normalize_to_utc(val)
    time =
      case val
      when Time, DateTime
        val.to_time
      when String
        parse_time_string(val)
      end

    time&.utc&.strftime(CANONICAL_FORMAT)
  end

  def parse_time_string(val)
    if CANONICAL_REGEX.match?(val)
      DateTime.strptime(val, CANONICAL_FORMAT).to_time
    elsif /(Z|[+-]\d{2}:?\d{2})\z/.match?(val)
      Time.iso8601(val)
    else
      User.current.time_zone.parse(val)
    end
  rescue ArgumentError
    nil
  end
end
