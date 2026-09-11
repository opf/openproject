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

# The RFC 5545 and RFC 5546 rules as a validation rule that we
# use in the custom rspec matcher be_a_conforming_calendar
class ICalConformance
  UTC_TIMESTAMPS = %i[dtstamp created last_modified].freeze

  def initialize(calendar)
    @calendar = calendar
  end

  def violations
    [
      single_uid_violations,
      count_and_until_violations,
      until_not_utc_violations,
      until_before_dtstart_violations,
      utc_timestamp_violations,
      override_violations
    ].flatten.compact
  end

  private

  attr_reader :calendar

  delegate :events, to: :calendar

  def single_uid_violations
    return [] unless %w[REQUEST CANCEL].include?(calendar.ip_method.to_s.upcase)

    uids = events.map { it.uid.to_s }.uniq
    return [] if uids.size <= 1

    ["METHOD:#{calendar.ip_method} carries #{uids.size} distinct UIDs: #{uids.join(', ')}"]
  end

  def count_and_until_violations
    each_rrule.filter_map do |event, recur|
      next if recur.count.nil? || recur.until.nil?

      "#{describe(event)} has COUNT=#{recur.count} and UNTIL=#{recur.until} in one RRULE"
    end
  end

  def until_not_utc_violations
    each_rrule.filter_map do |event, recur|
      next if recur.until.blank? || recur.until.end_with?("Z")
      next if tzid_of(event.dtstart).blank? && !utc?(event.dtstart)

      "#{describe(event)} has UNTIL=#{recur.until}, which is not UTC, against a zoned DTSTART"
    end
  end

  def until_before_dtstart_violations
    each_rrule.filter_map do |event, recur|
      ends_at = parse_ical_time(recur.until)
      next if ends_at.nil? || ends_at >= event.dtstart.to_time

      "#{describe(event)} ends at #{recur.until} before its DTSTART #{event.dtstart.value_ical}"
    end
  end

  def utc_timestamp_violations
    events.flat_map do |event|
      UTC_TIMESTAMPS.filter_map do |name|
        value = event.public_send(name)
        next if value.blank? || utc?(value)

        "#{name.to_s.tr('_', '-').upcase} of #{describe(event)} is not UTC: #{value.value_ical}"
      end
    end
  end

  def override_violations
    overrides.flat_map do |override|
      master = masters[override.uid.to_s]
      next [] if master.nil?

      [recurrence_id_before_dtstart(override, master), recurrence_id_off_grid(override, master)].compact
    end
  end

  def recurrence_id_before_dtstart(override, master)
    return if override.recurrence_id.to_time >= master.dtstart.to_time

    "#{describe(override)} has RECURRENCE-ID #{override.recurrence_id.value_ical} " \
      "before the master DTSTART #{master.dtstart.value_ical}"
  end

  def recurrence_id_off_grid(override, master)
    schedule = schedule_for(master)
    return schedule if schedule.is_a?(String)
    return if schedule.nil? || schedule.occurs_at?(local_time(override.recurrence_id))

    "#{describe(override)} has RECURRENCE-ID #{override.recurrence_id.value_ical}, " \
      "which is not an occurrence of #{master.rrule.first.value_ical}"
  end

  def masters
    @masters ||= events.reject { it.recurrence_id.present? }.index_by { it.uid.to_s }
  end

  def overrides
    @overrides ||= events.select { it.recurrence_id.present? }
  end

  def each_rrule
    events.flat_map { |event| event.rrule.map { |recur| [event, recur] } }
  end

  def schedule_for(master)
    @schedule_for ||= {}
    @schedule_for.fetch(master.uid.to_s) do
      @schedule_for[master.uid.to_s] = build_schedule(master)
    end
  end

  def build_schedule(master)
    recur = master.rrule.first
    return if recur.nil?

    rule = IceCube::Rule.from_ical(recur.value_ical)
    IceCube::Schedule.new(local_time(master.dtstart)).tap { it.add_recurrence_rule(rule) }
  rescue StandardError => e
    "the RRULE #{recur.value_ical} of #{describe(master)} could not be expanded: #{e.message}"
  end

  def local_time(value)
    zone = ActiveSupport::TimeZone[tzid_of(value).to_s] if tzid_of(value).present?
    return value.to_time if zone.nil?

    zone.parse(value.value_ical)
  end

  def parse_ical_time(raw)
    return if raw.blank?

    Icalendar::Values::DateTime.new(raw).to_time
  rescue StandardError
    nil
  end

  def tzid_of(value)
    Array(value.ical_params["tzid"]).first
  end

  def utc?(value)
    value.respond_to?(:tz_utc) && value.tz_utc
  end

  def describe(event)
    event.recurrence_id.present? ? "override #{event.uid}@#{event.recurrence_id.value_ical}" : "master #{event.uid}"
  end
end
