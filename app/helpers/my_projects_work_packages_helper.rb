#-- copyright
# OpenProject My Project Page Plugin
#
# Copyright (C) 2011-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
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
# See doc/COPYRIGHT.md for more details.
#++

module MyProjectsWorkPackagesHelper
  include WorkPackagesFilterHelper

  def types
    @types ||= project.rolled_up_types
  end

  def subproject_condition
    @subproject_condition ||= project.project_condition(Setting.display_subprojects_work_packages?)
  end

  def open_work_packages_by_type
    @open_work_packages_by_tracker ||= work_packages_by_type
                                       .where(statuses: { is_closed: false })
                                       .count
  end

  def total_work_packages_by_type
    @total_work_packages_by_tracker ||= work_packages_by_type.count
  end

  def work_packages_by_type
    WorkPackage
      .visible
      .joins(:project)
      .group(:type)
      .includes([:project, :status, :type])
      .references(:projects)
      .where(subproject_condition)
  end

  def assigned_work_packages
    @assigned_issues ||= WorkPackage
                         .visible
                         .open
                         .where(assigned_to: User.current.id)
                         .limit(10)
                         .includes([:status, :project, :type, :priority])
                         .order("#{IssuePriority.table_name}.position DESC,
                                 #{WorkPackage.table_name}.updated_on DESC")
  end
end
