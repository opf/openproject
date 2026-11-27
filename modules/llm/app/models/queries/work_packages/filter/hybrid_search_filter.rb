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

# Union of the text-based search filter and the semantic search filter.
#
# The filter stays registered (and thus valid in saved queries) even when semantic
# search is unavailable: the semantic arm degrades to "1=0" and the filter then
# matches exactly the text-based results. Unlike the semantic filter, a failed
# embedding is not a validation error here — hybrid search silently falls back to
# text search.
class Queries::WorkPackages::Filter::HybridSearchFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  def type
    :search
  end

  def human_name
    I18n.t("label_search_hybrid")
  end

  def where
    return "1=0" if values.first.blank?

    parts = [text_where, semantic_where].compact_blank
    return "1=0" if parts.empty?

    "(#{parts.join(') OR (')})"
  end

  # The text-based arm, exposed so the hybrid score select can rank text matches
  # in SQL. References the work_packages table of whatever query embeds it.
  def text_where
    text_filter.where
  end

  # The semantic arm, "1=0" when semantic search is unavailable or the query
  # cannot be embedded.
  def semantic_where
    return "1=0" if vector.nil? || semantic_index_id.nil?

    "#{WorkPackage.table_name}.id IN (" \
      "#{WorkPackageEmbedding.work_package_ids_within_search_distance_sql(vector, semantic_index_id:)})"
  end

  private

  def text_filter
    @text_filter ||= ::Queries::WorkPackages::Filter::SearchFilter.create!(
      name: :search, context:, operator: "**", values:
    )
  end

  def vector
    Llm::WorkPackages::SemanticSearch.query_vector(values.first)
  end

  def semantic_index_id
    Llm::WorkPackages::SemanticSearch.active_semantic_index&.id
  end
end
