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

module Notifications
  # Creates date alert jobs for users whose local time is 1:00 am.
  class ScheduleDateAlertsNotificationsJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      enqueue_limit: 1,
      perform_limit: 1
    )

    def perform
      return unless EnterpriseToken.allows_to?(:date_alerts)

      Service.new(times_from_scheduled_to_execution).call
    end

    # Returns times from scheduled execution time to current time in 15 minutes
    # steps.
    #
    # As scheduled execution time can be different from current time by more
    # than 15 minutes when workers are busy, all times at 15 minutes interval
    # between scheduled time and current time need to be considered to match
    # with 1:00am in a time zone.
    def times_from_scheduled_to_execution
      (scheduled_time.to_i..Time.current.to_i)
        .step(15.minutes)
        .map do |time|
        Time.zone.at(time)
      end
    end

    def scheduled_time
      GoodJob::Job
        .find(job_id)
        .cron_at
    end
  end
end
