# frozen_string_literal: true

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

class Queries::WorkPackages::Filter::SharedWithUserFilter <
  Queries::WorkPackages::Filter::PrincipalBaseFilter
  def available?
    super && view_shared_work_packages_allowed?
  end

  def scope
    query = visible_shared_work_packages(scoped_to_visible_projects: !querying_for_self?)

    if operator == '='
      query = query.where(shared_with_any_of_condition)
    elsif operator == '&='
      query = query.where(shared_with_all_of_condition)
    end

    WorkPackage.where(id: query.select('work_packages.id').distinct)
  end

  # Conditions handled in +scope+ method
  def where
    '1=1'
  end

  def human_name
    I18n.t('query_fields.shared_with_user')
  end

  def type
    :shared_with_user_list_optional
  end

  private

  def view_shared_work_packages_allowed?
    if project
      User.current.allowed_in_project?(:view_shared_work_packages, project)
    else
      User.current.allowed_in_any_project?(:view_shared_work_packages)
    end
  end

  def visible_shared_work_packages(scoped_to_visible_projects: true)
    base = WorkPackage
      .joins("JOIN members ON members.entity_type = 'WorkPackage' AND members.entity_id = work_packages.id")

    if scoped_to_visible_projects
      base.where(members: { project: visible_projects })
    else
      base
    end
  end

  def visible_projects
    Project.allowed_to(User.current, :view_shared_work_packages)
  end

  def shared_with_any_of_condition
    { members: { user_id: values_replaced } }
  end

  def shared_with_all_of_condition
    work_packages_table = WorkPackage.table_name
    members_table = Member.table_name

    where_clauses = values_replaced.map do |user_id|
      <<~SQL.squish
        EXISTS (SELECT 1
                FROM #{members_table}
                WHERE #{members_table}.entity_id = #{work_packages_table}.id
                AND #{members_table}.user_id = #{ActiveRecord::Base.connection.quote_string(user_id)})
      SQL
    end

    where_clauses.join(' AND ')
  end

  def querying_for_self?
    values_replaced.size == 1 && values_replaced.first == User.current.id.to_s
  end
end
