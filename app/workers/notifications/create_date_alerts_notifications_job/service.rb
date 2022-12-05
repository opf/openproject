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
# See COPYRIGHT and LICENSE files for more details.
#++

# Creates date alerts notifications for users whose local time is 1am for the
# given run_times.
class Notifications::CreateDateAlertsNotificationsJob::Service
  attr_reader :run_times

  # @param run_times [Array<DateTime>] the times for which the service is run.
  # Must be multiple of 15 minutes (xx:00, xx:15, xx:30, or xx:45).
  def initialize(run_times)
    @run_times = run_times
  end

  def call
    time_zones = time_zones_covering_1am_local_time
    return if time_zones.empty?

    # warning: there may be a subtle bug here: if many run_times are given, time
    # zones will have different time shifting. This should be ok: as the period
    # covered is small this should not have any impact. If the period is more
    # than 23h, then the day will change.
    Time.use_zone(time_zones.first) do
      User.with_time_zone(time_zones).find_each do |user|
        send_date_alert_notifications(user)
      end
    end
  end

  private

  def send_date_alert_notifications(user)
    alertables = Notifications::CreateDateAlertsNotificationsJob::AlertableWorkPackages.new(user)
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
    run_times.any? { |time| is_1am?(time, time_zone) }
  end

  def is_1am?(time, time_zone)
    local_time = time.in_time_zone(time_zone)
    local_time.strftime('%H:%M') == '01:00'
  end
end
