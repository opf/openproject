#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
      # Returns all users for which a reminder mails should be sent now. A user
      # will be included if:
      #
      # * That user has an unread notification
      # * The user hasn't been informed about the unread notification before
      # * The user has configured reminder mails to be within the time frame
      #   between the provided time and now.
      #
      # This assumes that users only have full hours specified for the times
      # they desire to receive a reminder mail at.
      #
      # @param [DateTime] earliest_time The earliest time to consider as a
      #   matching slot. All quarter hours from that time to now are included.
      #
      #   Only the time part is used which is moved forward to the next quarter
      #   hour (e.g. 2021-05-03 10:34:12+02:00 -> 08:45:00). This is done
      #   because time zones always have a mod(15) == 0 minutes offset. Needs to
      #   be before the current time.
      def having_reminder_mail_to_send(earliest_time)
        local_times = local_times_from(earliest_time)

        return none if local_times.empty?

        # Left outer join as not all user instances have preferences associated
        # but we still want to select them.
        recipient_candidates = User
                                 .active
                                 .left_joins(:preference)
                                 .joins(local_time_join(local_times))

        subscriber_ids = Notification
                           .unsent_reminders_before(recipient: recipient_candidates, time: Time.current)
                           .group(:recipient_id)
                           .select(:recipient_id)

        where(id: subscriber_ids)
      end

      def local_time_join(local_times)
        # Joins the times local to the user preferences and then checks whether:
        #
        #   * reminders are enabled
        #   * any of the configured reminder time is the local time
        #   * the local workday is enabled to receive a reminder on
        #
        # If no time zone is present or if it is blank, the configured default
        # time zone or UTC is assumed.
        #
        # If no reminder settings are present, sending a reminder at 08:00 local
        # time is assumed.
        #
        # If no workdays are specified, 1 - 5 is assumed which represents Monday
        # to Friday.
        times_sql = arel_table
                      .grouping(Arel::Nodes::ValuesList.new(local_times))
                      .as('t(today_local, hours, zone, workday)')

        default_timezone = Arel::Nodes::build_quoted(Setting.user_default_timezone.presence)

        <<~SQL.squish
          JOIN (SELECT * FROM #{times_sql.to_sql}) AS local_times
          ON COALESCE(NULLIF(user_preferences.settings->>'time_zone',''), #{default_timezone.to_sql}, 'Etc/UTC') = local_times.zone
          AND (
            user_preferences.settings->'workdays' @> to_jsonb(local_times.workday)
            OR (
              user_preferences.settings->'workdays' IS NULL
              AND local_times.workday BETWEEN 1 AND 5
            )
          )
          AND (
            (
              user_preferences.settings->'daily_reminders'->'times' IS NULL
              AND local_times.hours = '08:00:00+00:00'
            )
            OR
            (
              (user_preferences.settings->'daily_reminders'->>'enabled')::boolean
              AND user_preferences.settings->'daily_reminders'->'times' ? local_times.hours
            )
          )
          AND (
            (
              user_preferences.settings->'pause_reminders' IS NULL
              OR (user_preferences.settings->'pause_reminders'->>'enabled')::boolean = false
            )
            OR
            (
              (user_preferences.settings->'pause_reminders'->>'enabled')::boolean
              AND (
               local_times.today_local::date
               NOT BETWEEN (user_preferences.settings->'pause_reminders'->>'first_day')::date
               AND (user_preferences.settings->'pause_reminders'->>'last_day')::date
              )
            )
          )
        SQL
      end

      def local_times_from(earliest_time)
        times = quarters_between_earliest_and_now(earliest_time)

        times_for_zones(times)
      end

      def times_for_zones(times)
        UserPreferences::UpdateContract
          .assignable_time_zones
          .flat_map { |zone| build_local_times(times, zone) }
          .compact
      end

      def build_local_times(times, zone)
        times.map do |time|
          local_time = time.in_time_zone(zone)

          # Get the iso weekday of the current time to check
          # which users have it enabled as a workday
          workday = local_time.to_date.cwday

          # Get the corresponding date by conversion
          # to compare them with pause_reminder dates input from the users' frontend local times.
          local_date = local_time.to_date

          # Since only full hours can be configured, we can disregard any local time that is not
          # a full hour.
          next if local_time.min != 0

          [
            local_date,
            local_time.strftime('%H:00:00+00:00'),
            zone.tzinfo.canonical_zone.name,
            workday
          ]
        end
      end

      def quarters_between_earliest_and_now(earliest_time)
        latest_time = Time.current
        raise ArgumentError if latest_time < earliest_time || (latest_time - earliest_time) > 1.day

        quarters = ((latest_time - earliest_time) / 60 / 15).floor

        (1..quarters).each_with_object([next_quarter_hour(earliest_time)]) do |_, times|
          times << (times.last + 15.minutes)
        end
      end

      def next_quarter_hour(time)
        (time + (time.min % 15 == 0 ? 0.minutes : (15 - (time.min % 15)).minutes))
      end
    end
  end
end
