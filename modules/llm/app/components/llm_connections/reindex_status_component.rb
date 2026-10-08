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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  # Progress of the most recent re-index, read from the preserved GoodJob records.
  class ReindexStatusComponent < ApplicationComponent
    def render? = index_job.present?

    def batches
      @batches ||= GoodJob::Job
                     .where(job_class: "Llm::EmbedWorkPackagesJob")
                     .where(created_at: index_job.created_at..)
                     .order(:created_at)
                     .to_a
    end

    def finished_count = batches.count(&:finished_at)

    def failed_batches = batches.select { |job| job.error.present? }

    def percentage
      return 0 if batches.empty?

      finished_count * 100 / batches.size
    end

    def wall_clock
      started = batches.filter_map(&:performed_at).min
      ended = batches.filter_map(&:finished_at).max
      return if started.nil? || ended.nil?

      format_seconds(ended - started)
    end

    def average_duration
      durations = batches.filter_map { |job| seconds(job) }
      return if durations.empty?

      format_seconds(durations.sum / durations.size)
    end

    def status(job)
      if job.error.present? then job.error
      elsif job.finished_at then format_seconds(seconds(job))
      elsif job.performed_at then t("admin.work_package_embeddings.status.running")
      else t("admin.work_package_embeddings.status.queued")
      end
    end

    private

    def index_job
      @index_job ||= GoodJob::Job.where(job_class: "Llm::IndexWorkPackagesJob").order(created_at: :desc).first
    end

    def seconds(job)
      job.finished_at - job.performed_at if job.finished_at && job.performed_at
    end

    def format_seconds(value)
      value < 60 ? "#{value.round(2)}s" : ActiveSupport::Duration.build(value.round).inspect
    end
  end
end
