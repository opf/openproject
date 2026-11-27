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

# Orders work packages matched by the hybrid search filter by their reciprocal rank
# fusion (RRF) score, computed entirely in SQL: each work package's rank in the
# text-based result list (by recency) and in the semantic result list (by vector
# distance) contributes 1 / (RRF_K + rank). Work packages matched by both lists get
# both terms. Higher score sorts first ("desc").
#
# When the query cannot be embedded (feature flag off, no active index, embedding
# request failed), the semantic term is a NULL rank and scores 0, so the order
# degrades to the plain text ranking.
class Queries::WorkPackages::Selects::HybridScoreSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  RRF_K = 60

  # Constant fallback (always evaluates to 0, i.e. "no score"). Deliberately a CASE
  # expression, not a bare integer literal — Postgres treats a bare integer in ORDER BY
  # as a positional column reference, which a literal like "0" would trigger.
  NO_SCORE_SQL = "CASE WHEN 1 = 0 THEN 1 ELSE 0 END"

  def self.instances(_context = nil)
    new :hybrid_score,
        default_order: "desc",
        displayable: false,
        sortable: ->(query = nil) { rrf_order_sql(query) }
  end

  def self.rrf_order_sql(query)
    filter = query&.filters&.find { |f| f.field.to_s == "hybrid_search" }
    return NO_SCORE_SQL unless filter
    return NO_SCORE_SQL if filter.values.first.blank?

    "COALESCE(1.0 / (#{RRF_K} + (#{text_rank_sql(filter)})), 0) " \
      "+ COALESCE(1.0 / (#{RRF_K} + (#{semantic_rank_sql(filter.values.first)})), 0)"
  end

  # Rank of the work package within the text-matched set, most recently updated first.
  def self.text_rank_sql(filter)
    table = WorkPackage.table_name
    <<~SQL.squish
      (SELECT t.rn FROM (
        SELECT #{table}.id, ROW_NUMBER() OVER (ORDER BY #{table}.updated_at DESC, #{table}.id DESC) AS rn
        FROM #{table}
        WHERE (#{filter.text_where})
      ) AS t WHERE t.id = #{table}.id)
    SQL
  end

  # Rank of the work package within the semantic result set, most similar first.
  # NULL when the query vector is unavailable, scoring 0 in the RRF sum.
  def self.semantic_rank_sql(value)
    vector = Llm::WorkPackages::SemanticSearch.query_vector(value)
    semantic_index = Llm::WorkPackages::SemanticSearch.active_semantic_index
    return "NULL" if vector.nil? || semantic_index.nil?

    ranks = WorkPackageEmbedding.work_package_id_distance_ranks_sql(vector, semantic_index_id: semantic_index.id)
    <<~SQL.squish
      (SELECT t.rn FROM (#{ranks}) AS t WHERE t.id = #{WorkPackage.table_name}.id)
    SQL
  end
end
