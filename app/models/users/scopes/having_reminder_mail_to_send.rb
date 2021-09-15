#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module Users::Scopes
  module HavingReminderMailToSend
    extend ActiveSupport::Concern

    class_methods do
      # Returns all users for which a reminder mails should be sent now. A user will be included if:
      # * That user has an unread notification
      # * The user hasn't been informed about the unread notification before
      # * The user has configured reminder mails to be sent now.
      # This assumes that users only have full hours specified for the times they desire
      # to receive a reminder mail at.
      # @param [DateTime] earliest_time The earliest time to consider as a matching slot. All full hours from that time
      #   to now are included.
      #   Only the time part is used and that is floored to the hour (e.g. 2021-05-03 10:34:12+02:00 -> 08:00:00).
      #   Needs to be before the current time.
      def having_reminder_mail_to_send(earliest_time)
        # Left outer join as not all user instances have preferences associated
        # but we still want to select them.
        recipient_candidates = User
                                 .active
                                 .left_joins(:preference)
                                 .joins(local_time_join(earliest_time))

        subscriber_ids = Notification
                           .unsent_reminders_before(recipient: recipient_candidates, time: Time.current)
                           .group(:recipient_id)
                           .select(:recipient_id)

        where(id: subscriber_ids)
      end

      def local_time_join(earliest_time)
        # Joins the times local to the user preferences and then checks whether:
        # * reminders are enabled
        # * any of the configured reminder time is the local time
        # If no time zone is present, utc is assumed.
        # If no reminder settings are present, sending a reminder at 08:00 local time is assumed.
        <<~SQL.squish
          JOIN (#{local_time_table(earliest_time)}) AS local_times
          ON COALESCE(user_preferences.settings->>'time_zone', 'UTC') = local_times.zone
          AND (
            (
              user_preferences.settings->'daily_reminders'->'times' IS NULL
              AND local_times.time = '08:00:00+00:00'
            )
            OR
            (
              (user_preferences.settings->'daily_reminders'->'enabled')::boolean
              AND user_preferences.settings->'daily_reminders'->'times' ? local_times.time
            )
          )
        SQL
      end

      def local_time_table(earliest_time)
        times = hours_between_earliest_and_now(earliest_time)

        values_list = Arel::Nodes::ValuesList.new(times_for_zones(times))

        "SELECT * FROM #{arel_table.grouping(values_list).as('t(time, zone)').to_sql}"
      end

      def times_for_zones(times)
        ActiveSupport::TimeZone
          .all
          .map do |z|
            times.map do |time|
              [time.in_time_zone(z).strftime('%H:00:00+00:00'), z.name.gsub("'", "''")]
            end
          end
          .flatten(1)
      end

      def hours_between_earliest_and_now(earliest_time)
        raise ArgumentError if Time.current - earliest_time < 0

        (0..[((Time.current - earliest_time) / 1.hour).round, 24].min).map do |i|
          (earliest_time + i.hours).utc
        end
      end
    end
  end
end
