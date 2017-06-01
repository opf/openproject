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

class WorkPackage::SpentTime
  attr_accessor :user,
                :work_package

  def initialize(user, work_package = nil)
    @user = user
    @work_package = work_package
  end

  def scope
    with_spent_hours_joined
  end

  private

  def with_spent_hours_joined
    query = join_descendants(wp_table)
    query = join_time_entries(query)

    WorkPackage.joins(query.join_sources)
               .group(:id)
  end

  def join_descendants(select)
    descendants_join_condition = if work_package
                                   hierarchy_and_allowed_condition
                                     .and(wp_table[:id].eq(work_package.id))
                                 else
                                   hierarchy_and_allowed_condition
                                 end

    select
      .outer_join(wp_descendants)
      .on(descendants_join_condition)
  end

  def join_time_entries(select)
    join_condition = time_entries_table[:work_package_id]
                     .eq(wp_descendants[:id])
                     .and(allowed_to_view_time_entries)

    select
      .outer_join(time_entries_table)
      .on(join_condition)
  end

  def allowed_to_view_work_packages
    wp_descendants[:project_id].in(Project.allowed_to(user, :view_work_packages).select(:id).arel)
  end

  def allowed_to_view_time_entries
    time_entries_table[:id].in(TimeEntry.visible(user).select(:id).arel)
  end

  def hierarchy_and_allowed_condition
    self_or_descendant_condition
      .and(allowed_to_view_work_packages)
  end

  def self_or_descendant_condition
    nested_set_root_condition
      .and(nested_set_lft_condition)
      .and(nested_rgt_condition)
  end

  def nested_set_root_condition
    wp_descendants[:root_id].eq(wp_table[:root_id])
  end

  def nested_set_lft_condition
    wp_descendants[:lft].gteq(wp_table[:lft])
  end

  def nested_rgt_condition
    wp_descendants[:rgt].lteq(wp_table[:rgt])
  end

  def wp_table
    @wp_table ||= WorkPackage.arel_table
  end

  def wp_descendants
    @wp_descendants ||= wp_table.alias('descendants')
  end

  def time_entries_table
    @time_entries_table ||= TimeEntry.arel_table
  end
end
