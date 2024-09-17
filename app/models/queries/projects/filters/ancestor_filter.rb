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

class Queries::Projects::Filters::AncestorFilter < Queries::Projects::Filters::Base
  def apply_to(_query_scope)
    case operator
    when "="
      super
        .where(exists_condition.exists)
    when "!"
      super
        .where.not(exists_condition.exists)
    else
      raise "unsupported operator"
    end
  end

  def where
    nil
  end

  def type
    :list
  end

  def self.key
    :ancestor
  end

  private

  def type_strategy
    # Instead of getting the IDs of all the projects a user is allowed
    # to see we only check that the value is an integer.  Non valid ids
    # will then simply create an empty result but will not cause any
    # harm.
    @type_strategy ||= ::Queries::Filters::Strategies::IntegerList.new(self)
  end

  def exists_condition
    Project.from("#{Project.table_name} ancestors")
           .where(ancestor_condition.and(ancestor_in_values_condition))
           .arel
  end

  def ancestor_condition
    projects_table[:lft]
      .gt(projects_ancestor_table[:lft])
      .and(projects_table[:rgt].lt(projects_ancestor_table[:rgt]))
  end

  def ancestor_in_values_condition
    projects_ancestor_table[:id].in(values)
  end

  def projects_table
    Project.arel_table
  end

  def projects_ancestor_table
    projects_table.alias(:ancestors)
  end
end
