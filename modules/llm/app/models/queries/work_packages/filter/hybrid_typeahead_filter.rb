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

# Hybrid variant of the typeahead filter, used by the global search bar: the union
# of the typeahead conditions (subject, project/type/status names, IDs) and the
# semantic arm. Degrades to plain typeahead results when semantic search is
# unavailable or the query cannot be embedded.
class Queries::WorkPackages::Filter::HybridTypeaheadFilter <
  Queries::WorkPackages::Filter::HybridSearchFilter
  def joins
    %i[type status]
  end

  def text_joins_sql
    table = WorkPackage.table_name
    "INNER JOIN #{Project.table_name} ON #{Project.table_name}.id = #{table}.project_id " \
      "INNER JOIN #{Type.table_name} ON #{Type.table_name}.id = #{table}.type_id " \
      "INNER JOIN #{Status.table_name} ON #{Status.table_name}.id = #{table}.status_id"
  end

  private

  def text_filter
    @text_filter ||= ::Queries::WorkPackages::Filter::TypeaheadFilter.create!(
      name: :typeahead, context:, operator: "**", values:
    )
  end
end
