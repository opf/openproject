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

module ::Query::Sums
  include ActionView::Helpers::NumberHelper

  def all_total_sums
    summed_up_columns.inject({}) do |result, column|
      sum = total_sum_of(column)
      result[column] = sum unless sum.nil?
      result
    end
  end

  def all_sums_for_group(group)
    return nil unless query.grouped?

    core = WorkPackage
             .where(id: work_packages)
             .except(:order, :select)
             .group(query.group_by_statement)
             .select("#{query.group_by_statement} id, SUM(estimated_hours) estimated_hours")

    joins = callable_summed_up_columns
              .map { |c| "LEFT OUTER JOIN (#{c.summable.(query).to_sql}) #{c.name} ON #{c.name}.id = work_packages.id" }
              .join(' ')

    sql = <<~SQL
      SELECT *
      FROM (#{core.to_sql}) work_packages
      #{joins}
    SQL

    group_sums = ActiveRecord::Base.connection.select_all(sql)

    summed_up_columns.inject({}) do |result, column|
      value = if group.respond_to?(:id)
                group_sums.detect { |s| s['id'] == group.id }
              else
                group_sums.detect { |s| s['id'] == group }
              end
      result[column] = value[column.name.to_s] unless value.nil?
      result
    end
  end

  private

  def sum_of(column, collection)
    sum = column.sum_of(collection)

    crunch(sum)
  end

  def total_sum_of(column)
    #binding.pry
    #work_packages.sum(column.name)#
    sum_of(column, work_packages)
  end

  def crunch(num)
    return num if num.nil? || !num.respond_to?(:integer?) || num.integer?

    Float(format('%.2f', num.to_f))
  end

  def should_be_summed_up?(column)
    column.summable? && Setting.work_package_list_summable_columns.include?(column.name.to_s)
  end

  def summed_up_columns
    query.available_columns.select { |column| should_be_summed_up?(column) }
  end

  def callable_summed_up_columns
    query.available_columns.select { |column| should_be_summed_up?(column) && column.summable.respond_to?(:call) }
  end
end
