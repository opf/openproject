# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

class Queries::WorkPackages::Filter::SharedUserFilter <
  Queries::WorkPackages::Filter::PrincipalBaseFilter
  def available?
    super && User.current
                 .allowed_to?(:view_shared_work_packages,
                              project,
                              global: true)
  end

  def where
    operator_for_filtering.sql_for_field(shared_work_package_ids,
                                         WorkPackage.table_name,
                                         :id)
  end

  def human_name
    I18n.t('query_fields.shared_user')
  end

  def type
    :shared_user_list_optional
  end

  private

  def operator_for_filtering
    case operator
    when '*' # Shared with any user
      # Override the operator since we want to filter specifically
      # for shared work packages and not any work package
      ::Queries::Operators::Equals
    when '!*' # Shared with no one
      # Override the operator since we want to filter specifically
      # for those work packages that haven't been shared
      ::Queries::Operators::NotEquals
    else
      operator_strategy
    end
  end

  def shared_work_package_ids
    base_query = visible_shared_work_package_memberships

    unless %w[* !*].include?(operator)
      base_query = base_query.where(user_id: values_replaced)
    end

    base_query.select('entity_id')
              .distinct
              .pluck(:entity_id)
  end

  def visible_shared_work_package_memberships
    Member.where(entity_type: 'WorkPackage',
                 project: Project.allowed_to(User.current, :view_shared_work_packages))
  end
end
