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

class WorkPackageEmbedding < ApplicationRecord
  DIMENSIONS = 4000
  MAX_SEARCH_DISTANCE = 0.5
  SEARCH_LIMIT = 40

  belongs_to :semantic_index
  belongs_to :work_package

  def self.vector_literal(vector)
    values = Array(vector).map { Float(it) }
    if values.size > DIMENSIONS
      raise ArgumentError, "Embedding has #{values.size} dimensions, at most #{DIMENSIONS} are supported"
    end

    padded = values + Array.new(DIMENSIONS - values.size, 0.0)
    "[#{padded.join(',')}]"
  end

  def embedding=(vector)
    super(self.class.vector_literal(vector))
  end

  # The distance threshold must stay outside the materialized CTE: inside it, the
  # hnsw.iterative_scan session setting would keep scanning (up to hnsw.max_scan_tuples)
  # whenever fewer than :limit embeddings are within the threshold. Restricting to
  # +work_packages+ inside it, on the other hand, lets the iterative scan fill the LIMIT
  # with work packages that survive that restriction.
  # https://github.com/pgvector/pgvector#iterative-search-options
  def self.work_package_ids_within_search_distance_sql(vector_literal, semantic_index_id:, work_packages:,
                                                       limit: SEARCH_LIMIT)
    nearest = where(semantic_index_id:, work_package_id: work_packages.select(:id))
                .select(:work_package_id, sanitize_sql_array(["embedding <=> ? AS distance", vector_literal]))
                .order(Arel.sql("distance"))
                .limit(limit.to_i)

    "WITH nearest AS MATERIALIZED (#{nearest.to_sql}) " \
      "SELECT work_package_id FROM nearest " \
      "WHERE distance < #{MAX_SEARCH_DISTANCE} " \
      "ORDER BY distance"
  end

  def self.distance_to_work_package_sql(vector_literal, semantic_index_id:)
    sanitize_sql_array([<<~SQL.squish, { semantic_index_id:, vector_literal: }])
      (SELECT embedding <=> :vector_literal FROM #{table_name}
       WHERE #{table_name}.semantic_index_id = :semantic_index_id
         AND #{table_name}.work_package_id = #{WorkPackage.table_name}.id)
    SQL
  end
end
