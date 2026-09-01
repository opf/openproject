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

module Queries::Projects::Filters::FilterOnProjectType
  def type
    :list
  end

  def where
    exists = enabled_project_types.arel.exists

    operator_strategy == Queries::Operators::NotEquals ? exists.not : exists
  end

  def autocomplete_options
    all_items = allowed_values.map { |name, id| { name:, id: id.to_s } }
    {
      component: "opce-autocompleter",
      bindValue: "id",
      bindLabel: "name",
      hideSelected: true,
      defaultData: false,
      items: all_items,
      model: all_items.select { |item| values.include?(item[:id]) }
    }
  end

  private

  def project_type_column
    raise SubclassResponsibilityError
  end

  def enabled_project_types
    ProjectType
      .where(ProjectType.arel_table[:project_id].eq(Project.arel_table[:id]))
      .where(Queries::Operators::Equals.sql_for_field(values, ProjectType.table_name, project_type_column))
  end
end
