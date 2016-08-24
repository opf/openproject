#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class Authorization::UserAllowedQuery < Authorization::AbstractUserQuery
  self.model = User

  transformations.register :all,
                           :member_roles_join do |statement|
    statement.outer_join(member_roles_table)
             .on(members_member_roles_join)
  end

  transformations.register :all,
                           :where_projection do |statement, action, project|
    statement = statement.group(users_table[:id])

    # No action allowed on archived projects
    # No action allowed on disabled modules
    if project.active? && project.allows_to?(action)
      statement.where(roles_table[:id].not_eq(nil).or(users_table[:admin].eq(true)))
    else
      statement.where(Arel::Nodes::Equality.new(1, 0))
    end
  end

  transformations.register users_members_join,
                           :project_id_limit do |statement, _, project|
    statement.and(members_table[:project_id].eq(project.id))
  end

  transformations.register :all,
                           :roles_join,
                           after: [:member_roles_join] do |statement, action, project|
    statement.outer_join(roles_table)
             .on(roles_member_roles_join(action, project))
  end

  def self.roles_member_roles_join(action, project)
    id_equal = roles_table[:id].eq(member_roles_table[:role_id])
    id_equal_or_public = if project.is_public?
                           member_or_public_project_condition(id_equal)
                         else
                           id_equal
                         end

    if Redmine::AccessControl.permission(action).public?
      id_equal_or_public
    else
      id_equal_or_public.and(roles_table[:permissions].matches("%#{action}%"))
    end
  end

  def self.no_membership_and_non_member_role_condition
    roles_table
      .grouping(member_roles_table[:role_id]
                .eq(nil)
                .and(roles_table[:builtin].eq(Role::BUILTIN_NON_MEMBER)))
  end

  def self.anonymous_user_condition
    users_table[:type]
      .eq('AnonymousUser')
      .and(roles_table[:builtin].eq(Role::BUILTIN_ANONYMOUS))
  end

  def self.member_or_public_project_condition(id_equal)
    roles_table
      .grouping(users_table[:type]
                .eq('User')
                .and(id_equal.or(no_membership_and_non_member_role_condition)))
      .or(anonymous_user_condition)
  end
end
