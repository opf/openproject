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

class Queries::WorkPackages::Filter::SemanticSearchFilter <
  Queries::WorkPackages::Filter::WorkPackageFilter
  delegate :available?, to: "Llm::WorkPackages::SemanticSearch"

  def type
    :search
  end

  def human_name
    I18n.t("label_search_by_meaning")
  end

  def where
    return "1=0" if vector.nil?

    "#{WorkPackage.table_name}.id IN (" \
      "#{WorkPackageEmbedding.work_package_ids_within_search_distance_sql(vector, semantic_index_id:)})"
  end

  protected

  def validate_values
    super

    return unless errors.empty?
    return if values.first.blank?
    return unless Llm::WorkPackages::SemanticSearch.available?

    errors.add(:values, :semantic_search_unavailable) if vector.nil?
  end

  private

  def vector
    Llm::WorkPackages::SemanticSearch.query_vector(values.first)
  end

  def semantic_index_id
    Llm::WorkPackages::SemanticSearch.active_semantic_index&.id
  end
end
