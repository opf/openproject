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
    # Work packages whose embedding is missing or older than their last update.
    class IndexCandidates
      delegate :none?, to: :work_packages

      def initialize(semantic_index)
        @semantic_index = semantic_index
      end

      def work_packages
        WorkPackage.where(up_to_date_embedding.arel.exists.not)
      end

      # Updates that leave the embedded text unchanged only advance
      # work_package_updated_at, so they do not cost a new embedding.
      def skip_unchanged_text!
        WorkPackageEmbedding.connection.update(WorkPackageEmbedding.sanitize_sql_array([<<~SQL.squish, semantic_index.id]))
          UPDATE work_package_embeddings
          SET work_package_updated_at = work_packages.updated_at
          FROM work_packages
          WHERE work_package_embeddings.work_package_id = work_packages.id
            AND work_package_embeddings.semantic_index_id = ?
            AND work_packages.updated_at > work_package_embeddings.work_package_updated_at
            AND work_package_embeddings.text_digest = #{EmbeddableText::DIGEST_SQL}
        SQL
      end

      private

      attr_reader :semantic_index

      def embeddings = WorkPackageEmbedding.where(semantic_index:)

      def up_to_date_embedding
        embeddings
          .where(embeddings_table[:work_package_id].eq(work_packages_table[:id]))
          .where(embeddings_table[:work_package_updated_at].gteq(work_packages_table[:updated_at]))
      end

      def embeddings_table = WorkPackageEmbedding.arel_table

      def work_packages_table = WorkPackage.arel_table
    end
  end
end
