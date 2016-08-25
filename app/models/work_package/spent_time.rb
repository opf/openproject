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

class WorkPackage::SpentTime
  attr_accessor :user,
                :work_package

  def initialize(user, work_package = nil)
    @user = user
    @work_package = work_package
  end

  def scope(table_alias)
    with_spent_hours_joined(table_alias)
  end

  private

  def with_spent_hours_joined(table_alias)
    subselect = spent_hours_select.as(table_alias)

    wp_table = WorkPackage.arel_table

    joined_aggregated_entries = wp_table
                                .outer_join(subselect)
                                .on(subselect[:id].eq(wp_table[:id]))

    WorkPackage.joins(joined_aggregated_entries.join_sources)
  end

  def spent_hours_select
    select = id_and_hours_as_result

    join_descendants(select)
    check_descendant_visibility(select)
    join_time_entries(select)
    check_time_entry_visibility(select)

    group_by_wp_id(select)
  end

  def id_and_hours_as_result
    wp_table
      .project(wp_target[:id], time_entries_table[:hours].sum.as('hours'))
      .from(wp_target)
  end

  def join_descendants(select)
    descendants_join_condition = if work_package
                                   hierarchy_condition
                                     .and(wp_target[:id].eq(work_package.id))
                                 else
                                   hierarchy_condition
                                 end

    select
      .join(wp_descendants, Arel::Nodes::OuterJoin)
      .on(descendants_join_condition)
  end

  def join_time_entries(select)
    select
      .join(time_entries_table)
      .on(time_entries_table[:work_package_id].eq(wp_descendants[:id]))
  end

  def check_descendant_visibility(select)
    select
      .join(descendants_projects)
      .on(descendants_projects[:id].eq(wp_descendants[:project_id]))
      .where(allowed_to_view_work_packages)
  end

  def check_time_entry_visibility(select)
    select
      .where(allowed_to_view_time_entries)
  end

  def group_by_wp_id(select)
    select.group(wp_target[:id])
  end

  def allowed_to_view_work_packages
    descendants_projects[:id].in(Project.allowed_to(user, :view_work_packages).select(:id).arel)
  end

  def allowed_to_view_time_entries
    time_entries_table[:id].in(TimeEntry.visible(user).select(:id).arel)
  end

  def hierarchy_condition
    root_eql = wp_descendants[:root_id].eq(wp_target[:root_id])
    lft_gteq = wp_descendants[:lft].gteq(wp_target[:lft])
    rgt_lteq = wp_descendants[:rgt].lteq(wp_target[:rgt])

    root_eql
      .and(lft_gteq)
      .and(rgt_lteq)
  end

  def wp_table
    @wp_table ||= WorkPackage.arel_table
  end

  def wp_target
    @wp_target ||= wp_table.alias('target')
  end

  def wp_descendants
    @wp_descendants ||= wp_table.alias('descendants')
  end

  def time_entries_table
    @time_entries_table ||= TimeEntry.arel_table
  end

  def projects_table
    @projects_table ||= Project.arel_table
  end

  def descendants_projects
    @descendants_projects ||= projects_table.alias('descendants_projects')
  end

  def time_entry_projects
    @time_entry_projects ||= projects_table.alias('time_entry_projects')
  end
end
