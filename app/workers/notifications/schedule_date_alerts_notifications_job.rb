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

module Notifications
  # Creates date alert jobs for users whose local time is 1:00 am.
  # The job is scheduled to run every 15 minutes.
  class ScheduleDateAlertsNotificationsJob < ApplicationJob
    include Cron::QuarterHourScheduleJob

    def perform
      return unless EnterpriseToken.allows_to?(:date_alerts)

      Service.new(every_quater_hour_between_predecessor_cron_at_and_own_cron_at).call
    end

    # What cannot be controlled is the time at which a job is actually performed.
    # A high load on the system can lead to a job being performed later than expected.
    #
    # It might also happen that due to some outage of the background workers, cron
    # jobs are not enqueued as they should be.
    #
    # But we want to achieve even under these circumstances that date alerts are sent out
    # for all the users even if we cannot guarantee that they are sent out at the time where we want it to happen
    # which would be 1:00 am. At the same time we want to prevent date alerts being sent out multiple times.
    #
    # There are three scenarios to consider which mostly circle around the predecessor
    # of the job that is currently run:
    # * The predecessor ran successfully within the 15 minutes interval between it being scheduled and the current job
    #   having to run. If this is the case, then the current job will only have to handle only the point in time of
    #   its cron_at value.
    # * The predecessor took longer to run than 15 minutes or was scheduled to run at a later time (because its)
    #   predecessor was delayed. This will potentially lead to the current job also being delayed. If this is the case,
    #   then the current job will have to handle all the 15 minute slots between its cron_at value and the cron_at value
    #   of its predecessor + 15 minutes.
    # * There is no predecessor since it is the first job ever to run or for some reasons the GoodJob::Execution where
    #   salvaged. In this case there is no certainty as to what is the right choice which is why the cron_at value of
    #   the current job is again used as the sole point in time to consider.
    #
    # In other words, the current job will take the
    # * cron_at value of the current job as the maximum time to consider.
    # * Take the cron_at of the previous job + 15 minutes as the minimum time to consider.
    # If no previous job exists, then the cron_at of the current job is the minimum.
    #
    # Using this pattern, between all the instances of this job, every time slot where there is the potential
    # for 1:00 am local time are covered. The sole exception would be the case where previously finished jobs
    # have been removed from the database and the current job took longer to start executing. This is for now
    # an accepted shortcoming as the likelihood of this happening is considered to be very low.
    def every_quater_hour_between_predecessor_cron_at_and_own_cron_at
      (lower_boundary.to_i..upper_boundary.to_i)
        .step(15.minutes)
        .map do |time|
        Time.zone.at(time)
      end
    end
  end
end
