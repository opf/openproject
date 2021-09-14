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
      # This assumes that users only have full hours specified for the time they desire
      # to receive a reminder mail.
      def having_reminder_mail_to_send_now
        # Left outer join as not all user instances have preferences associated
        # but we still want to select them.
        recipient_candidates = User
                                 .active
                                 .left_joins(:preference)
                                 .joins(local_time_join)

        subscriber_ids = Notification
                           .unsent_reminders_before(recipient: recipient_candidates, time: Time.current)
                           .group(:recipient_id)
                           .select(:recipient_id)

        where(id: subscriber_ids)
      end

      def local_time_join
        <<~SQL.squish
          JOIN (#{local_time_table}) AS local_times
          ON COALESCE(user_preferences.settings->>'time_zone', 'UTC') = local_times.zone
          AND local_times.time = '#{Setting.notification_email_digest_time}:00+00:00'
        SQL
      end

      def local_time_table
        current_time = Time.current

        times_with_zones = ActiveSupport::TimeZone
                           .all
                           .map do |z|
                             [current_time.in_time_zone(z).strftime('%H:00:00+00:00'), z.name.gsub("'", "''")]
                           end

        "SELECT * FROM #{arel_table.grouping(Arel::Nodes::ValuesList.new(times_with_zones)).as('t(time, zone)').to_sql}"
      end
    end
  end
end
