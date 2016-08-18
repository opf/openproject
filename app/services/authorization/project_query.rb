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

class Authorization::ProjectQuery
  # Returns a SQL conditions string used to find all projects for which +user+
  # has the given +permission+
  #
  # Valid options:
  # * project: limit the condition to project
  # * with_subprojects: limit the condition to project and its subprojects
  # * member: limit the condition to the user projects
  # * project_alias: the alias to use for the project's table - default: 'projects'
  def self.query(user, permission, options = {})
    table_alias = options.fetch(:project_alias, Project.table_name)

    base_statement = "#{table_alias}.status=#{Project::STATUS_ACTIVE}"
    if perm = Redmine::AccessControl.permission(permission)
      unless perm.project_module.nil?
        # If the permission belongs to a project module, make sure the module is enabled
        module_query = enabled_module_query(perm.project_module,
                                            options[:project],
                                            options[:with_subproject])
        base_statement << " AND #{table_alias}.id IN (#{module_query})"
      end
    end
    if options[:project]
      project_statement = "#{table_alias}.id = #{options[:project].id}"
      if options[:with_subprojects]
        project_statement << " OR (#{descendants_condition(options[:project], table_alias)})"
      end
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end

    if user.admin?
      base_statement
    else
      statement_by_role = {}
      if user.logged?
        if Role.non_member.allowed_to?(permission) && !options[:member]
          non_member_statements = [public_project_condition(table_alias)]

          member_project_ids = user.memberships.map(&:project_id)

          unless member_project_ids.empty?
            non_member_statements << "#{table_alias}.id NOT IN (#{member_project_ids.join(', ')})"
          end

          statement_by_role[Role.non_member] = non_member_statements.join(" AND ")
        end
        user.projects_by_role.each do |role, projects|
          if role.allowed_to?(permission)
            statement_by_role[role] = "#{table_alias}.id IN (#{projects.map(&:id).join(',')})"
          end
        end
      elsif Role.anonymous.allowed_to?(permission) && !options[:member]
        statement_by_role[Role.anonymous] = public_project_condition(table_alias)
      end
      if statement_by_role.empty?
        '1=0'
      else
        "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
      end
    end
  end

  def self.enabled_module_query(project_module, project, with_subprojects)
    enabled_module_statement = "SELECT em.project_id FROM #{EnabledModule.table_name} em"

    if project && with_subprojects
      enabled_module_statement << " JOIN #{table_alias} ON #{table_alias}.id = em.project_id"
    end

    enabled_module_statement << " WHERE em.name='#{project_module}'"

    if project
      project_statement = "em.project_id = #{project.id}"

      if with_subprojects
        project_statement << " OR (#{descendants_condition(project, table_alias)})"
      end

      enabled_module_statement << " AND (#{project_statement})"
    end

    enabled_module_statement
  end

  def self.descendants_condition(project, table_alias)
    "#{table_alias}.lft > #{project.lft} AND #{table_alias}.rgt < #{project.rgt}"
  end

  def self.public_project_condition(table_alias)
    "#{table_alias}.is_public = #{Project.connection.quoted_true}"
  end
end
