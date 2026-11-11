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
    include GoodJob::ActiveJobExtensions::Batches

    queue_with_priority :low

    def self.enqueue_for(semantic_index)
      GoodJob::Batch.enqueue(on_finish: Llm::FinishSemanticIndexingJob, semantic_index_id: semantic_index.id) do
        perform_later(semantic_index.id)
      end
    end

    def perform(semantic_index_id)
      return unless OpenProject::Llm::Features[:semantic_search].available?

      semantic_index = SemanticIndex.find_by(id: semantic_index_id)
      return unless semantic_index&.indexing?

      return fail_indexing(semantic_index, :no_connection) unless LlmConnection.available?

      return fail_indexing(semantic_index, :model_missing) unless offers_embedding_model?(semantic_index.model_id)

      batch.add do
        WorkPackage.find_in_batches(batch_size: 100) do |work_packages|
          Llm::EmbedWorkPackagesJob.perform_later(semantic_index_id, work_packages.map(&:id))
        end
      end
    end

    private

    def offers_embedding_model?(model_id)
      LlmConnection.active_connection.embedding_model_ids.include?(model_id)
    end

    def fail_indexing(semantic_index, status)
      message = I18n.t(status, scope: "admin.semantic_indexes.indexing.not_ready", model: semantic_index.model_id)
      semantic_index.fail_indexing!(message)
    end
  end
end
