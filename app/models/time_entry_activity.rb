#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class TimeEntryActivity < Enumeration
  has_many :time_entries, foreign_key: 'activity_id'
  has_many :time_entry_activities_projects, foreign_key: 'activity_id', dependent: :delete_all

  validates :parent, absence: true

  def self.in_project(project)
    scope = includes(time_entry_activities_projects: :activity)

    scope
      .where(time_entry_activities_projects: { project_id: project.id, active: true })
      .or(scope.where.not(time_entry_activities_projects: { project_id: project.id }).where(enumerations: { active: true }))
      .or(scope.where(time_entry_activities_projects: { project_id: nil }, enumerations: { active: true }))
  end

  OptionName = :enumeration_activities

  def option_name
    OptionName
  end

  def objects_count
    time_entries.count
  end

  def transfer_relations(to)
    time_entries.update_all(activity_id: to.id)
  end

  def active_in_project?(project)
    teap = time_entry_activities_projects.detect { |t| t.project_id == project.id }
    !teap || teap.active?
  end

  def activated_projects
    join_condition = <<-SQL
      LEFT OUTER JOIN time_entry_activities_projects
        ON projects.id = time_entry_activities_projects.project_id
        AND time_entry_activities_projects.activity_id = #{id}
    SQL

    join_scope = Project.joins(join_condition)

    result_scope = join_scope.where(time_entry_activities_projects: { active: true })

    if active?
      result_scope
        .or(join_scope.where(time_entry_activities_projects: { project_id: nil }))
    else
      result_scope
    end
  end
end
