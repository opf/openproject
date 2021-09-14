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
  module HavingReminderMailToSendNow
    extend ActiveSupport::Concern

    class_methods do
      # Returns all users for which a reminder mails should be sent now. A user will be included if:
      # * That user has an unread notification
      # * The user hasn't been informed about the unread notification before
      # * The user has configured reminder mails to be sent now.
      def having_reminder_mail_to_send_now
        # Left outer join as not all user instances have preferences associated
        # but we still want to select them
        recipient_candidates = User.active
                                   .left_joins(:preference)
                                   .where(where_statement)

        subscriber_ids = Notification
                           .unsent_reminders_before(recipient: recipient_candidates, time: Time.current)
                           .group(:recipient_id)
                           .select(:recipient_id)

        User.where(id: subscriber_ids)
      end

      def where_statement
        current_timestamp_utc = Time.current.getutc

        age = age_statement(current_timestamp_utc)
        <<-SQL.squish
        #{age} < make_interval(mins=>30)
        AND
        #{age} >= make_interval(mins=>0)
        SQL
      end

      # Creates a SQL snippet for calculating the time between now and
      # the reminder time slot with the each user's time zone
      # @param [Time] current_timestamp_utc
      def age_statement(current_timestamp_utc)
        year = current_timestamp_utc.year
        month = current_timestamp_utc.month
        day = current_timestamp_utc.day

        case_statement = case_statement_zone_name_to_offset

        slot_time = Time.zone.parse(Setting.notification_email_digest_time)

        <<-SQL.squish
        age(
          now(),
          make_timestamptz(#{year}, #{month}, #{day}, #{slot_time.hour}, #{slot_time.min}, 0, (#{case_statement}))
        )
        SQL
      end

      def case_statement_zone_name_to_offset
        return @case_statement_zone_name_to_offset if @case_statement_zone_name_to_offset

        current_time = Time.current
        statement = ActiveSupport::TimeZone.all.map do |zone|
          offset = current_offset(zone, current_time)
          "WHEN user_preferences.settings->>'time_zone' = '#{zone.name.gsub("'") { "''" }}' THEN '#{offset}'"
        end
        @case_statement_zone_name_to_offset = "CASE\n#{statement.join("\n")}\nELSE '+00:00'\nEND"
      end

      # The real offset of a time zone depends of the moment we ask. Winter and summer time
      # have different offsets of UTC. For instance, time zone "Berlin" in winter has +01:00
      # and in summer +02:00
      # @param [Time] time
      # @param [TimeZone] zone
      # @return [String]
      def current_offset(zone, time = Time.current)
        time.in_time_zone(zone).formatted_offset
      end
    end
  end
end
