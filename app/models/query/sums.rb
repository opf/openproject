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

  def total_sum_of(column)
    sum_of(column, work_packages)
  end

  def sum_of(column, collection)
    return nil unless should_be_summed_up?(column)

    sum = column.sum_of(collection)

    crunch(sum)
  end

  def mapping_for(column)
    if column.respond_to? :real_value
      method(:number_to_currency)
    else
      # respond_to? :call, but do nothing
      @nilproc ||= Proc.new { |val| val }
    end
  end

  def crunch(num)
    return num if num.nil? || !num.respond_to?(:integer?) || num.integer?

    Float(format('%.2f', num.to_f))
  end

  def should_be_summed_up?(column)
    column.summable? && Setting.work_package_list_summable_columns.include?(column.name.to_s)
  end

  def column_total_sums
    query.columns.map { |column| total_sum_of(column) }
  end

  def all_total_sums
    query.available_columns.select { |column|
      should_be_summed_up?(column)
    }.inject({}) { |result, column|
      sum = total_sum_of(column)
      result[column] = sum unless sum.nil?
      result
    }
  end

  def all_sums_for_group(group)
    return nil unless query.grouped?

    group_work_packages = work_packages.select { |wp| query.group_by_column.value(wp) == group }
    query.available_columns.inject({}) do |result, column|
      sum = sum_of(column, group_work_packages)
      result[column] = sum unless sum.nil?
      result
    end
  end
end
