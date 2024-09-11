# -- copyright
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
# ++

module Cron::QuarterHourScheduleJob
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency

    # With good_job and the limit of only allowing a single job to be enqueued and
    # also a single job being performed at the same time we end up having
    # up to two jobs that are not yet finished.

    good_job_control_concurrency_with(
      enqueue_limit: 1,
      perform_limit: 1
    )

    # The job is scheduled to run every 15 minutes. If the job before takes longer
    # than expected we retry two more times (at cron_at + 5 and cron_at + 15). Then the job is discarded.
    # Once the job is discarded, the next job will be scheduled to run at the next quarter hour.
    retry_on GoodJob::ActiveJobExtensions::Concurrency::ConcurrencyExceededError,
             wait: 5.minutes,
             attempts: 3
  end

  private

  def upper_boundary
    @upper_boundary ||= good_job.cron_at
  end

  def lower_boundary
    @lower_boundary ||= begin
      # The cron_key is used here to find the predecessor job.
      # The job_class has been used before as a comparison but this fails in
      # the SaaS environment where multiple tenants exist. The cron_key gets the
      # tenant information prepended and is thus scoped to the tenant.
      predecessor = GoodJob::Job
                      .succeeded
                      .where(cron_key: good_job.cron_key)
                      .where("cron_at < ?", upper_boundary)
                      .order(cron_at: :desc)
                      .first

      if predecessor
        # To ovoid the jobs spanning a very long time e.g after a longer downtime, the interval
        # is limited to a somewhat arbitrary 24 hours.
        # On the other hand the two jobs currently making use of this module have a time reference where
        # it would not make sense to send very old data (i.e. reminders or date alerts)
        [upper_boundary - 24.hours, predecessor.cron_at + 15.minutes].max
      else
        upper_boundary
      end
    end
  end

  def good_job
    @good_job ||= GoodJob::Job.find(job_id)
  end
end
