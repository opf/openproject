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

# Orders the work packages matched by the semantic search filter from most to least similar.
# Sort it "asc": the value is the vector distance to the search query.
class Queries::WorkPackages::Selects::SemanticSimilaritySelect < Queries::WorkPackages::Selects::WorkPackageSelect
  # A bare integer in ORDER BY would be read as a column position.
  NO_SIMILARITY_SQL = "CASE WHEN 1 = 0 THEN 1 ELSE 0 END"

  def self.instances(_context = nil)
    new :semantic_similarity,
        default_order: "asc",
        displayable: false,
        sortable: ->(query = nil) { similarity_order_sql(query) }
  end

  def self.similarity_order_sql(query)
    filter = query&.filters&.find { |f| f.field.to_s == "semantic_search" }
    return NO_SIMILARITY_SQL unless filter

    semantic_index = Llm::WorkPackages::SemanticSearch.active_semantic_index
    vector = Llm::WorkPackages::SemanticSearch.query_vector(filter.values.first)
    return NO_SIMILARITY_SQL if vector.nil? || semantic_index.nil?

    WorkPackageEmbedding.distance_to_work_package_sql(vector, semantic_index_id: semantic_index.id)
  end
end
