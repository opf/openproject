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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Notifications
  # Creates date alert jobs for users whose local time is 1:00 am.
  class ScheduleDateAlertsNotificationsJob < Cron::CronJob
    # runs every quarter of an hour, so 00:00, 00:15,..., 15:30, 15:45, 16:00, ...
    self.cron_expression = '*/15 * * * *'

    def perform
      return unless EnterpriseToken.allows_to?(:date_alerts)

      service = Service.new(times_from_scheduled_to_execution)
      service.call
    end

    # Returns times from scheduled execution time to current time in 15 minutes
    # steps.
    #
    # As scheduled execution time can be different from current time by more
    # than 15 minutes when workers are busy, all times at 15 minutes interval
    # between scheduled time and current time need to be considered to match
    # with 1:00am in a time zone.
    def times_from_scheduled_to_execution
      time = scheduled_time
      times = []
      begin
        times << time
        time += 15.minutes
      end while time < Time.current
      times
    end

    def scheduled_time
      self.class.delayed_job.run_at.then { |t| t.change(min: t.min / 15 * 15) }
    end
  end
end
