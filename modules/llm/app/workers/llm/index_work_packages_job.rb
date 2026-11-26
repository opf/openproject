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

module Llm
  class IndexWorkPackagesJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    queue_with_priority :low

    BATCH_SIZE = 100

    good_job_control_concurrency_with(
      total_limit: 1,
      key: -> { self.class.concurrency_key(arguments.first || SemanticIndex.active_id) }
    )

    def self.concurrency_key(semantic_index_id) = "llm-index-work-packages-#{semantic_index_id}"

    # without an id it syncs the active semantic index, as run by cron
    def perform(semantic_index_id = nil)
      return unless OpenProject::Llm::Features[:semantic_search].available?

      semantic_index = find_semantic_index(semantic_index_id)
      return if semantic_index.blank? || semantic_index.indexing_batch_running?
      return if update_prerequisite_error(semantic_index)

      candidates = Llm::WorkPackages::IndexCandidates.new(semantic_index)
      candidates.skip_unchanged_text!
      return if candidates.none?

      enqueue_embed_jobs(semantic_index, candidates.work_packages)
    end

    private

    def find_semantic_index(id) = id ? SemanticIndex.find_by(id:) : SemanticIndex.active

    def update_prerequisite_error(semantic_index)
      error_message = semantic_index.prerequisite_error
      semantic_index.update!(error_message:) if semantic_index.error_message != error_message
      error_message
    end

    def enqueue_embed_jobs(semantic_index, work_packages)
      batch = GoodJob::Batch.new(semantic_index_id: semantic_index.id).tap(&:save)
      semantic_index.update!(indexing_batch_id: batch.id)

      work_packages.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch_of_work_packages|
        batch.add { Llm::EmbedWorkPackagesJob.perform_later(semantic_index.id, batch_of_work_packages.map(&:id)) }
      end
    end
  end
end
