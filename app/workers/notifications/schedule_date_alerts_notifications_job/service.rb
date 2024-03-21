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

# Creates date alerts notifications for users whose local time is 1am for the
# given run_times.
class Notifications::ScheduleDateAlertsNotificationsJob::Service
  attr_reader :run_times

  # @param run_times [Array<DateTime>] the times for which the service is run.
  # Must be multiple of 15 minutes (xx:00, xx:15, xx:30, or xx:45).
  def initialize(run_times)
    @run_times = run_times
  end

  def call
    return unless EnterpriseToken.allows_to?(:date_alerts)

    users_at_1am_with_notification_settings.find_each do |user|
      Notifications::CreateDateAlertsNotificationsJob.perform_later(user)
    end
  end

  private

  def time_zones_covering_1am_local_time
    UserPreferences::UpdateContract
      .assignable_time_zones
      .select { |time_zone| executing_at_1am_for_timezone?(time_zone) }
      .map { |time_zone| time_zone.tzinfo.canonical_zone.name }
      .uniq
  end

  def executing_at_1am_for_timezone?(time_zone)
    run_times.any? { |time| is_1am?(time, time_zone) }
  end

  def is_1am?(time, time_zone)
    local_time = time.in_time_zone(time_zone)
    local_time.strftime('%H:%M') == '01:00'
  end

  def users_at_1am_with_notification_settings
    User
      .with_time_zone(time_zones_covering_1am_local_time)
      .not_locked
      .where("EXISTS (SELECT 1 FROM notification_settings " \
             "WHERE user_id = users.id AND " \
             "(overdue IS NOT NULL OR start_date IS NOT NULL OR due_date IS NOT NULL))")
  end
end
