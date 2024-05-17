# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2024 the OpenProject GmbH
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
  end

  private

  def upper_boundary
    @upper_boundary ||= GoodJob::Job
                          .find(job_id)
                          .cron_at
  end

  def lower_boundary
    @lower_boundary ||= begin
      predecessor = GoodJob::Job
                      .succeeded
                      .where(job_class: self.class.name)
                      .order(cron_at: :desc)
                      .first

      if predecessor
        predecessor.cron_at + 15.minutes
      else
        upper_boundary
      end
    end
  end
end
