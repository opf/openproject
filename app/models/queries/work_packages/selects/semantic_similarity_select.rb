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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++
# Orders the work packages matched by the semantic search filter from most to least similar.
# Sort it "asc": the value is the rank of each work package within the semantic results.
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

    ids = Search::SemanticResult.ranked_ids(filter.values.first).map { |id| Integer(id) }
    return NO_SIMILARITY_SQL if ids.empty?

    "array_position(ARRAY[#{ids.join(',')}]::bigint[], #{WorkPackage.table_name}.id)"
  end
end
