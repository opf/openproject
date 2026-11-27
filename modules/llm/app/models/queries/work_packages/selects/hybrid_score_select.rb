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
# distance) contributes weight / (RRF_K + rank). Work packages matched by both lists
# get both terms. Higher score sorts first ("desc").
#
# When the query cannot be embedded (feature flag off, no active index, embedding
# request failed), the semantic term is a NULL rank and scores 0, so the order
# degrades to the plain text ranking.
class Queries::WorkPackages::Selects::HybridScoreSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  RRF_K = 60
  TEXT_WEIGHT = 2.0
  SEMANTIC_WEIGHT = 1.0

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

  HYBRID_FILTER_FIELDS = %w[hybrid_search hybrid_typeahead].freeze

  def self.rrf_order_sql(query)
    filter = query&.filters&.find { |f| HYBRID_FILTER_FIELDS.include?(f.field.to_s) }
    return NO_SCORE_SQL unless filter
    return NO_SCORE_SQL if filter.search_term.blank?

    "COALESCE(#{TEXT_WEIGHT} / (#{RRF_K} + (#{text_rank_sql(filter)})), 0) " \
      "+ COALESCE(#{SEMANTIC_WEIGHT} / (#{RRF_K} + (#{semantic_rank_sql(filter)})), 0)"
  end

  # Rank of the work package within the text-matched set. The plain hybrid search
  # ranks by recency; the hybrid typeahead mirrors the typeahead sort (exact
  # id/identifier match first, then recency).
  def self.text_rank_sql(filter)
    table = WorkPackage.table_name
    <<~SQL.squish
      (SELECT t.rn FROM (
        SELECT #{table}.id, ROW_NUMBER() OVER (ORDER BY #{text_rank_order_sql(filter)}) AS rn
        FROM #{table} #{filter.text_joins_sql}
        WHERE (#{filter.text_where})
      ) AS t WHERE t.id = #{table}.id)
    SQL
  end

  def self.text_rank_order_sql(filter)
    table = WorkPackage.table_name
    if filter.field.to_s == "hybrid_typeahead"
      exact_match = ::Queries::WorkPackages::Selects::ExactMatchSelect
        .exact_match_condition_sql(filter.search_term)
      exact_match ||= ::Queries::WorkPackages::Selects::ExactMatchSelect::NO_EXACT_MATCH_SQL
      "#{exact_match} DESC, #{table}.updated_at DESC, #{table}.id DESC"
    else
      "#{table}.updated_at DESC, #{table}.id DESC"
    end
  end

  # Rank of the work package within the semantic result set, most similar first.
  # NULL when the query vector is unavailable, scoring 0 in the RRF sum.
  def self.semantic_rank_sql(filter)
    vector = filter.query_vector
    semantic_index = Llm::WorkPackages::SemanticSearch.active_semantic_index
    return "NULL" if vector.nil? || semantic_index.nil?

    ranks = WorkPackageEmbedding.work_package_id_distance_ranks_sql(vector, semantic_index_id: semantic_index.id)
    <<~SQL.squish
      (SELECT t.rn FROM (#{ranks}) AS t WHERE t.id = #{WorkPackage.table_name}.id)
    SQL
  end
end
