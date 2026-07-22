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

module Queries::Projects::Filters::AncestorWorkspaceTypeFilter
  include Queries::Filters::Shared::ProjectFilter::Optional

  def apply_to(_query_scope)
    case operator
    when "="  then super.where(exists_condition.exists)
    when "!"  then super.where.not(exists_condition.exists)
    when "*"  then super.where(any_exists_condition.exists)
    when "!*" then super.where.not(any_exists_condition.exists)
    else raise "unsupported operator"
    end
  end

  def where = nil

  def available?
    EnterpriseToken.allows_to?(:portfolio_management) &&
    Project.workspace_type(self.class.key.to_s).visible.exists?
  end

  def autocomplete_options
    super.merge(
      resource: self.class.key.to_s.pluralize,
      url: ::API::V3::Utilities::PathHelper::ApiV3Path.public_send(self.class.key.to_s.pluralize)
    )
  end

  private

  def exists_condition
    Project.from("#{Project.table_name} ancestors")
           .where(ancestor_condition.and(ancestor_workspace_type_condition).and(ancestor_in_values_condition))
           .arel
  end

  def any_exists_condition
    Project.from("#{Project.table_name} ancestors")
           .where(ancestor_condition.and(ancestor_workspace_type_condition))
           .arel
  end

  def ancestor_condition
    projects_table[:lft].gt(projects_ancestor_table[:lft])
      .and(projects_table[:rgt].lt(projects_ancestor_table[:rgt]))
  end

  def ancestor_workspace_type_condition
    projects_ancestor_table[:workspace_type].eq(self.class.key.to_s)
  end

  def ancestor_in_values_condition
    projects_ancestor_table[:id].in(values)
  end

  def projects_table = Project.arel_table

  def projects_ancestor_table = projects_table.alias(:ancestors)
end
