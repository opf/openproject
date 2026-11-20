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
  class EmbedWorkPackagesJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Batches

    queue_with_priority :low

    discard_on StandardError do |job, _error|
      job.enqueue_per_work_package
    end

    retry_on Llm::Errors::RateLimitedError, wait: :polynomially_longer, attempts: 10

    def perform(semantic_index_id, work_package_ids)
      return unless OpenProject::Llm::Features[:semantic_search].available?

      semantic_index = SemanticIndex.find_by(id: semantic_index_id)
      return if semantic_index.blank?

      work_packages = WorkPackage.where(id: work_package_ids)
      Llm::WorkPackages::EmbedService.new(semantic_index, work_packages).call
    end

    def enqueue_per_work_package
      semantic_index_id, work_package_ids = arguments
      return if work_package_ids.size < 2

      if batch
        batch.add { enqueue_individually(semantic_index_id, work_package_ids) }
      else
        enqueue_individually(semantic_index_id, work_package_ids)
      end
    end

    private

    def enqueue_individually(semantic_index_id, work_package_ids)
      work_package_ids.each { |work_package_id| self.class.perform_later(semantic_index_id, [work_package_id]) }
    end
  end
end
