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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module LlmConnections
  class IndexingStatusComponent < ApplicationComponent
    include OpTurbo::Streamable

    POLL_INTERVAL_MS = 2000

    def render? = batch.present?

    def state
      return :running unless batch.finished?

      batch.discarded? ? :failed : :succeeded
    end

    def running? = state == :running

    def progress_color = state == :failed ? :danger_emphasis : :success_emphasis

    def failed_count
      @failed_count ||= embed_jobs.where.not(finished_at: nil).where.not(error: nil).count
    end

    def percentage
      return state == :succeeded ? 100 : 0 if total_count.zero?

      finished_count * 100 / total_count
    end

    def wrapper_data_attrs
      return {} unless running?

      {
        data: {
          controller: "poll-for-changes",
          poll_for_changes_url_value: status_work_package_embeddings_path,
          poll_for_changes_interval_value: POLL_INTERVAL_MS
        }
      }
    end

    private

    def batch
      @batch ||= Llm::IndexWorkPackagesJob.latest_batch
    end

    def embed_jobs = batch.jobs.where(job_class: Llm::EmbedWorkPackagesJob.name)

    def total_count
      @total_count ||= embed_jobs.count
    end

    def finished_count
      @finished_count ||= embed_jobs.where.not(finished_at: nil).count
    end
  end
end
