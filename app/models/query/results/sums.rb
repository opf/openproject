#-- encoding: UTF-8
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

module ::Query::Results::Sums
  include ActionView::Helpers::NumberHelper

  def all_total_sums
    group_sums = sums_select

    query.summed_up_columns.inject({}) do |result, column|
      value = group_sums.first
      result[column] = value[column.name.to_s] unless value.nil?
      result
    end
  end

  def all_group_sums
    return nil unless query.grouped?

    sums_by_id = sums_select.inject({}) do |result, group_sum|
      result[group_sum['id']] = {}

      query.summed_up_columns.each do |column|
        result[group_sum['id']][column] = group_sum[column.name.to_s]
      end

      result
    end

    transform_group_keys(sums_by_id)
  end

  private

  def sums_select
    select = if query.grouped?
               ["work_packages.id"]
             else
               []
             end

    select += query.summed_up_columns.map(&:name)

    sql = <<~SQL
      SELECT #{select.join(', ')}
      FROM (#{sums_work_package_scope.to_sql}) work_packages
      #{sums_callable_joins}
    SQL

    ActiveRecord::Base.connection.select_all(sql)
  end

  def sums_work_package_scope
    scope = WorkPackage
            .where(id: work_packages)
            .except(:order, :select)
            .select(sums_work_package_scope_selects)

    if query.grouped?
      scope.group(query.group_by_statement)
    else
      scope
    end
  end

  def sums_callable_joins
    callable_summed_up_columns
      .map do |c|
        join_condition = if query.grouped?
                           "#{c.name}.id = work_packages.id OR #{c.name}.id IS NULL AND work_packages.id IS NULL"
                         else
                           "TRUE"
                         end

        "LEFT OUTER JOIN (#{c.summable.(query).to_sql}) #{c.name} ON #{join_condition}"
      end
      .join(' ')
  end

  def sums_work_package_scope_selects
    select = if query.grouped?
               ["#{query.group_by_statement} id"]
             else
               []
             end

    select + non_callable_summed_up_columns.map { |c| "SUM(#{c.name}) #{c.name}" }
  end

  def callable_summed_up_columns
    query.summed_up_columns.select { |column| column.summable.respond_to?(:call) }
  end

  def non_callable_summed_up_columns
    query.summed_up_columns.reject { |column| column.summable.respond_to?(:call) }
  end
end
