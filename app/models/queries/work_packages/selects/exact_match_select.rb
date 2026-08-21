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

# Used for sorting exact matches first in a search.
# Should be combined with another sort order, e.g. `[["exactMatch","desc"],["updatedAt","desc"]]`.
# Currently only typeahead searches are supported.
class Queries::WorkPackages::Selects::ExactMatchSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  # Constant fallback (always evaluates to 0, i.e. "no boost"). Deliberately a CASE
  # expression, not a bare integer literal — Postgres treats a bare integer in ORDER BY
  # as a positional column reference, which a literal like "0" would trigger.
  NO_EXACT_MATCH_SQL = "CASE WHEN 1 = 0 THEN 1 ELSE 0 END"

  def self.instances(_context = nil)
    new :exact_match,
        default_order: "desc",
        displayable: false,
        sortable: ->(query = nil) { exact_match_order_sql(query) }
  end

  # Ranks work packages whose numeric id or semantic identifier is an exact match for
  # the query's active typeahead search term first when sorted "desc"; falls back to a
  # constant (no reordering) when no typeahead filter is active, or its value isn't
  # boostable.
  def self.exact_match_order_sql(query)
    typeahead_filter = query&.filters&.find { |filter| filter.field.to_s == "typeahead" }
    return NO_EXACT_MATCH_SQL unless typeahead_filter

    exact_match_condition_sql(typeahead_filter.values.join(" ")) || NO_EXACT_MATCH_SQL
  end

  # Returns a SQL fragment ("CASE WHEN <exact-match> THEN 1 ELSE 0 END") that evaluates to 1
  # for work packages whose numeric id, sequence number or semantic identifier exactly equals
  # query_string, and 0 otherwise — sort this column "desc" to bring exact matches to the top.
  # Which field a bare number is compared against depends on the work packages identifier mode.
  # Returns nil when query_string is blank, multi-word (exact-match boosting only applies
  # to the whole trimmed string), or matches neither shape.
  def self.exact_match_condition_sql(query_string)
    stripped = query_string.to_s.strip
    return nil if stripped.blank? || stripped.match?(/\s/)

    hash_prefixed = stripped.start_with?("#")
    candidate = stripped.delete_prefix("#")
    condition =
      if candidate.match?(/\A[1-9]\d*\z/)
        numeric_exact_match_condition(candidate, hash_prefixed:)
      elsif candidate.match?(/\A#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source}\z/i)
        semantic_exact_match_condition(candidate, hash_prefixed:)
      end

    return nil unless condition

    "CASE WHEN #{condition} THEN 1 ELSE 0 END"
  end

  def self.numeric_exact_match_condition(candidate, hash_prefixed:)
    if Setting::WorkPackageIdentifier.classic? || hash_prefixed
      OpenProject::SqlSanitization.sanitize(
        "#{WorkPackage.table_name}.id = ?", candidate.to_i
      )
    else
      OpenProject::SqlSanitization.sanitize(
        "#{WorkPackage.table_name}.sequence_number = ?", candidate.to_i
      )
    end
  end

  def self.semantic_exact_match_condition(candidate, hash_prefixed:)
    return nil unless Setting::WorkPackageIdentifier.semantic? || hash_prefixed

    # So far, semantic identifiers are always upper case.
    # We can leverage this to match in a way that allows index usage.
    OpenProject::SqlSanitization.sanitize(
      "#{WorkPackage.table_name}.id IN (SELECT work_package_id FROM " \
      "#{WorkPackageSemanticAlias.table_name} WHERE identifier = ?)",
      candidate.upcase
    )
  end
end
