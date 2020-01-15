#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

module OpenProject::Costs::Patches::WorkPackageEagerLoadingPatch
  def self.prepended(base)
    class << base
      prepend ClassMethods
    end
  end

  def self.join_costs(scope)
    # The core adds a "LEFT OUTER JOIN time_entries" where the on clause
    # allows all time entries to be joined if he has the :view_time_entries.
    # Costs will add another "LEFT OUTER JOIN time_entries". The two joins
    # may or may not include each other's rows depending on the user's and the project's permissions.
    # This is caused by entries being joined if he has
    # the :view_time_entries permission and additionally those which are
    # his and for which he has the :view_own_time_entries permission.
    # Because of that, entries may be joined twice.
    # We therefore modify the core's join by placing it in a subquery similar to those of costs.
    #
    # This is very hacky.
    #
    # We also have to remove the sum calcualtion for time_entries.hours as
    # the calculation is later on performed within the subquery added by
    # LaborCosts. With it, we can use the value as it is calculated by the subquery.
    time_join = core_with_joined_time(scope)

    reject_core_time_entries(scope)

    target_scope = new_scope_with_costs(scope, time_join)

    reject_core_descendants(target_scope)
    reject_core_grouping(target_scope)

    target_scope
  end

  def self.core_with_joined_time(scope)
    time = scope.dup

    wp_table = WorkPackage.arel_table

    wp_table
      .outer_join(time.arel.as('spent_time_hours'))
      .on(wp_table[:id].eq(time.arel_table.alias('spent_time_hours')[:id]))
  end

  def self.new_scope_with_costs(scope, time_join)
    material_scope = work_package_material_scope(scope)
    labor_scope = work_package_labor_scope(scope)

    scope
      .joins(material_scope.arel.join_sources)
      .joins(labor_scope.arel.join_sources)
      .joins(time_join.join_sources)
      .select(material_scope.select_values)
      .select(labor_scope.select_values)
      .select('spent_time_hours.hours')
  end

  def self.work_package_material_scope(scope)
    WorkPackage::MaterialCosts
      .new
      .add_to_work_package_collection(scope.dup)
  end

  def self.work_package_labor_scope(scope)
    WorkPackage::LaborCosts
      .new
      .add_to_work_package_collection(scope.dup)
  end

  def self.reject_core_time_entries(scope)
    scope.joins_values.reject! do |join|
      join.is_a?(Arel::Nodes::OuterJoin) &&
        join.left.is_a?(Arel::Table) &&
        join.left.name == 'time_entries'
    end
    scope.select_values.reject! do |select|
      select == "SUM(time_entries.hours) AS hours"
    end
  end

  def self.reject_core_descendants(scope)
    scope.joins_values.reject! do |join|
      join.is_a?(Arel::Nodes::OuterJoin) &&
        join.left.is_a?(Arel::Nodes::TableAlias) &&
        join.left.right == 'descendants'
    end
  end

  def self.reject_core_grouping(scope)
    scope.group_values.reject! do |group|
      group == :id
    end
  end

  module ClassMethods
    def add_eager_loading(*args)
      ::OpenProject::Costs::Patches::WorkPackageEagerLoadingPatch.join_costs(super)
    end
  end
end
