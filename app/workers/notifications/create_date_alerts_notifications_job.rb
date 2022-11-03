#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Notifications
  # Creates date alerts for users whose local time is 1:00 am.
  class CreateDateAlertsNotificationsJob < Cron::CronJob
    # runs every quarter of an hour, so 00:00, 00:15,..., 15:30, 15:45, 16:00, ...
    self.cron_expression = '*/15 * * * *'

    def perform
      time_zones = time_zones_covering_1am_local_time
      return if time_zones.empty?

      Time.use_zone(time_zones.first) do
        User.with_time_zone(time_zones).find_each do |user|
          send_date_alert_notifications(user)
        end
      end
    end

    def send_date_alert_notifications(user)
      alertables = AlertableWorkPackages.new(user)
      create_date_alert_notifications(user, alertables.alertable_for_start, :date_alert_start_date)
      create_date_alert_notifications(user, alertables.alertable_for_due, :date_alert_due_date)
    end

    def create_date_alert_notifications(user, work_packages, reason)
      mark_previous_notifications_as_read(user, work_packages, reason)
      work_packages.find_each do |work_package|
        create_date_alert_notification(user, work_package, reason)
      end
    end

    def mark_previous_notifications_as_read(user, work_packages, reason)
      Notification
        .where(recipient: user,
               reason:,
               resource: work_packages)
        .update_all(read_ian: true, updated_at: Time.current)
    end

    def create_date_alert_notification(user, work_package, reason)
      create_service = Notifications::CreateService.new(user:)
      create_service.call(
        recipient_id: user.id,
        project_id: work_package.project_id,
        resource: work_package,
        reason:
      )
    end

    def time_zones_covering_1am_local_time
      UserPreferences::UpdateContract
        .assignable_time_zones
        .select { |time_zone| executing_at_1am_for_timezone?(time_zone) }
        .map { |time_zone| time_zone.tzinfo.canonical_zone.name }
    end

    def executing_at_1am_for_timezone?(time_zone)
      times_from_scheduled_to_execution.any? { |time| is_1am?(time, time_zone) }
    end

    def is_1am?(time, time_zone)
      local_time = time.in_time_zone(time_zone)
      local_time.strftime('%H:%M') == '01:00'
    end

    # Returns times from scheduled execution time to current time in 15 minutes
    # steps.
    #
    # As scheduled execution time can be different from current time by more
    # than 15 minutes when workers are busy, all times at 15 minutes interval
    # between scheduled time and current time need to be considered to match
    # with 1:00am in a time zone.
    def times_from_scheduled_to_execution
      @times_from_scheduled_to_execution ||= begin
        time = scheduled_time
        times = []
        begin
          times << time
          time += 15.minutes
        end while time < Time.current
        times
      end
    end

    def scheduled_time
      @scheduled_time ||=
        self.class.delayed_job.run_at.then { |t| t.change(min: t.min / 15 * 15) }
    end
  end
end
