#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Queries::WorkPackages::Filter::RoleFilter < Queries::WorkPackages::Filter::WorkPackageFilter
  def allowed_values
    @allowed_values ||= begin
      roles.map { |r| [r.name, r.id.to_s] }
    end
  end

  def available?
    roles.exists?
  end

  def type
    :list_optional
  end

  def order
    7
  end

  def human_name
    I18n.t('query_fields.assigned_to_role')
  end

  def self.key
    :assigned_to_role
  end

  def ar_object_filter?
    true
  end

  def value_objects
    value_ints = values.map(&:to_i)

    roles.select { |r| value_ints.include?(r.id) }
  end

  def where
    operator_for_filtering.sql_for_field(user_ids_for_filtering.map(&:to_s),
                                         WorkPackage.table_name,
                                         'assigned_to_id')
  end

  private

  def roles
    ::Role.givable
  end

  def operator_for_filtering
    case operator
    when '*' # Any Role
      # Override the operator since we want to find by assigned_to
      ::Queries::Operators::Equals
    when '!*' # No role
      # Override the operator since we want to find by assigned_to
      ::Queries::Operators::NotEquals
    else
      operator_strategy
    end
  end

  def user_ids_for_filtering
    scope = if ['*', '!*'].include?(operator)
              user_ids_for_filtering_scope
            elsif project
              user_ids_for_filter_project_scope
            else
              user_ids_for_filter_non_project_scope
            end

    scope.pluck(:user_id).sort.uniq
  end

  def user_ids_for_filtering_scope
    roles
      .joins(member_roles: :member)
  end

  def user_ids_for_filter_project_scope
    user_ids_for_filtering_scope
      .where(id: values)
      .where(members: { project_id: project.id })
  end

  def user_ids_for_filter_non_project_scope
    user_ids_for_filtering_scope
      .where(id: values)
  end
end
