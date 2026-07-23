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

class Queries::WorkPackages::Filter::TypeaheadFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def type
    :search
  end

  def joins
    %i[type status]
  end

  def where
    parts = values.map(&:split).flatten

    parts.map do |part|
      conditions = [subject_condition(part),
                    project_name_condition(part),
                    work_package_identifier_condition(part),
                    type_name_condition(part),
                    status_condition(part)]

      if (match = part.match(/^#?(\d+)$/))
        conditions << id_condition(match[1])
      end

      "(#{conditions.join(' OR ')})"
    end.join(" AND ")
  end

  def subject_condition(string)
    Queries::Operators::Contains.sql_for_field([string], WorkPackage.table_name, "subject")
  end

  def project_name_condition(string)
    Queries::Operators::Contains.sql_for_field([string], Project.table_name, "name")
  end

  def work_package_identifier_condition(string)
    alias_condition = Queries::Operators::StartsWith.sql_for_field(
      [string], WorkPackageSemanticAlias.table_name, "identifier"
    )
    "#{WorkPackage.table_name}.id IN " \
      "(SELECT work_package_id FROM #{WorkPackageSemanticAlias.table_name} WHERE #{alias_condition})"
  end

  def type_name_condition(string)
    Queries::Operators::Contains.sql_for_field([string], Type.table_name, "name")
  end

  def status_condition(string)
    # Check if the search string matches translated "open" or "closed" meta statuses
    open_term = I18n.t("label_open").downcase
    closed_term = I18n.t("label_closed").downcase
    search_term = string.downcase

    if search_term == open_term
      # Match meta statuses that are not closed (open statuses)
      "#{Status.table_name}.is_closed = false"
    elsif search_term == closed_term
      # Match meta statuses that are closed
      "#{Status.table_name}.is_closed = true"
    else
      # Match statuses by name
      Queries::Operators::Contains.sql_for_field([string], Status.table_name, "name")
    end
  end

  def id_condition(string)
    "#{WorkPackage.table_name}.id::varchar(20) LIKE '%#{string}%'"
  end

  # Returns a SQL fragment ("CASE WHEN <exact-match> THEN 1 ELSE 0 END") that evaluates to 1
  # for work packages whose numeric id or semantic identifier exactly equals query_string,
  # and 0 otherwise — sort this column "desc" to bring exact matches to the top (the
  # conventional direction for a boolean-shaped flag, e.g. ORDER BY is_featured DESC).
  # Returns nil when query_string is blank, multi-word (exact-match boosting only applies
  # to the whole trimmed string), or matches neither shape.
  def self.exact_match_order_sql(query_string)
    stripped = query_string.to_s.strip
    return nil if stripped.blank? || stripped.match?(/\s/)

    numeric_candidate = stripped.delete_prefix("#") # mirrors id_condition's `#?` prefix

    condition =
      if numeric_candidate.match?(/\A\d+\z/)
        OpenProject::SqlSanitization.sanitize(
          "#{WorkPackage.table_name}.id::varchar(20) = ?", numeric_candidate
        )
      elsif stripped.match?(/\A#{WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN.source}\z/i)
        OpenProject::SqlSanitization.sanitize(
          "#{WorkPackage.table_name}.id IN (SELECT work_package_id FROM " \
          "#{WorkPackageSemanticAlias.table_name} WHERE lower(identifier) = lower(?))",
          stripped
        )
      end

    return nil unless condition

    "CASE WHEN #{condition} THEN 1 ELSE 0 END"
  end
end
