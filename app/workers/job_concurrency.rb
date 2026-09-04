# frozen_string_literal: true

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

module JobConcurrency
  extend ActiveSupport::Concern

  included do
    include GoodJob::ActiveJobExtensions::Concurrency
  end

  ##
  # Run the concurrency check of good_job without actually trying to enqueue it
  # Will call the provided block in case the job would be cancelled
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  def check_concurrency
    enqueue_limit = self.class.good_job_concurrency_config[:enqueue_limit]
    enqueue_limit = instance_exec(&enqueue_limit) if enqueue_limit.respond_to?(:call)
    enqueue_limit = nil unless enqueue_limit.present? && (0...Float::INFINITY).cover?(enqueue_limit)

    unless enqueue_limit
      total_limit = self.class.good_job_concurrency_config[:total_limit]
      total_limit = instance_exec(&total_limit) if total_limit.respond_to?(:call)
      total_limit = nil unless total_limit.present? && (0...Float::INFINITY).cover?(total_limit)
    end

    limit = enqueue_limit || total_limit
    # Regression #OP-19861
    # Count ALL unfinished jobs, including ones currently performing. Excluding
    # advisory-locked (running) jobs allowed a second settings save while
    # ApplyWorkingDaysChangeJob was still running; GoodJob then aborted enqueue
    # of the follow-up job.
    enqueued_jobs = GoodJob::Job.where(concurrency_key: good_job_concurrency_key).unfinished.count

    yield if limit.present? && enqueued_jobs + 1 > limit
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/AbcSize
end
