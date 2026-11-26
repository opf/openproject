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
  module WorkPackages
    class EmbedService
      def initialize(semantic_index, work_package_ids)
        @semantic_index = semantic_index
        @work_package_ids = work_package_ids
      end

      def call
        return if work_packages.empty?

        raise Llm::Errors::NotReady, :no_connection unless LlmConnection.available?

        store(embed)
      rescue Llm::Errors::InvalidInputError
        # Only a request for a single work package proves its text is refused.
        raise unless work_packages.one?

        record_failure
      end

      private

      attr_reader :semantic_index

      # clear embedding, set failed_at
      # update work_package_updated_at so we only try again when the work package is updated
      def record_failure
        upsert(work_packages.map { |work_package| row(work_package, embedding: nil, failed_at: Time.current) })
      end

      # digest must be computed when retrieving work packages to avoid drift
      def work_packages
        @work_packages ||= EmbeddableText.with_digest(WorkPackage.where(id: @work_package_ids)).to_a
      end

      def connection
        @connection ||= LlmConnection.active_connection
      end

      def session = Llm::Session.for(connection)

      def embed
        session.embed(texts, model: semantic_index.model_id, dimensions: semantic_index.embedding_vector_dimensions).vectors
      end

      def texts
        work_packages.map { |wp| EmbeddableText.for(wp, context_window: semantic_index.context_token_length) }
      end

      def store(vectors)
        rows = work_packages.zip(vectors).map do |work_package, vector|
          row(work_package, embedding: WorkPackageEmbedding.vector_literal(vector), failed_at: nil)
        end

        upsert(rows)
      end

      def row(work_package, **attributes)
        {
          semantic_index_id: semantic_index.id,
          work_package_id: work_package.id,
          work_package_updated_at: work_package.updated_at,
          text_digest: work_package.text_digest,
          **attributes
        }
      end

      def upsert(rows)
        return if rows.empty?

        WorkPackageEmbedding.transaction(requires_new: true) do
          WorkPackageEmbedding.upsert_all(rows, unique_by: %i[semantic_index_id work_package_id])
        end
      rescue ActiveRecord::InvalidForeignKey
        existing_ids = WorkPackage.where(id: rows.pluck(:work_package_id)).ids
        upsert(rows.select { |row| existing_ids.include?(row[:work_package_id]) })
      end
    end
  end
end
