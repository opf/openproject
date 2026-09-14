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

module Meeting::VirtualStartTime
  extend ActiveSupport::Concern

  included do
    include VirtualAttribute

    # We only save start_time as an aggregated value of start_date and hour,
    # but still need start_date and _hour for validation purposes
    virtual_attribute :start_date do
      @start_date
    end
    virtual_attribute :start_time_hour do
      @start_time_hour
    end

    validate :validate_date_and_time
    after_initialize :set_initial_values
    before_save :update_start_time!
  end

  ##
  # Actually sets the aggregated start_time attribute.
  def update_start_time!
    self[:start_time] = start_time
  end

  ##
  # Validate date and time setters.
  # If start_time has been changed, check that value.
  # Otherwise start_{date, time_hour} was used, then validate those
  def validate_date_and_time
    if parse_start_time?
      errors.add :start_date, :not_an_iso_date if parsed_start_date.nil?
      errors.add :start_time_hour, :invalid_time_format if parsed_start_time_hour.nil?
    elsif start_time.nil?
      errors.add :start_time, :invalid
    end
  end

  ##
  # Determines whether new raw values were provided.
  def parse_start_time?
    changed.intersect?(%w(start_date start_time_hour))
  end

  ##
  # Returns the parse result of both start_date and start_time_hour
  def parsed_start_time
    date = parsed_start_date
    time = parsed_start_time_hour

    return if date.nil? || time.nil?

    time_zone.local(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.min
    )
  end

  def set_initial_values
    self[:start_time] = default_start_time if start_time.nil?
    update_derived_fields
  end

  ##
  # Defaults to now, rounded up to the next half hour
  def default_start_time
    now = time_zone.now.change(sec: 0)
    now + ((30 - (now.min % 30)) % 30).minutes
  end

  ##
  # Return the computed start_time when changed
  def start_time
    if parse_start_time?
      parsed_start_time
    else
      super
    end
  end

  def start_time=(value)
    super(value&.to_datetime)
    update_derived_fields
  end

  def update_derived_fields
    @start_date = format_date(start_time, time_zone:, format: "%Y-%m-%d")
    @start_time_hour = format_time(start_time, time_zone:, include_date: false, format: "%H:%M")
  end

  ##
  # Enforce ISO 8601 date parsing for the given input string
  # This avoids weird parsing of dates due to malformed input.
  def parsed_start_date
    return @start_date if @start_date.is_a?(Date)

    Date.iso8601(@start_date)
  rescue ArgumentError
    nil
  end

  ##
  # Enforce HH::MM time parsing for the given input string
  def parsed_start_time_hour
    return nil if @start_time_hour.nil?

    Time.strptime(@start_time_hour, "%H:%M")
  rescue ArgumentError, TypeError
    nil
  end
end
