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

module ::Query::Sums
  include ActionView::Helpers::NumberHelper

  def all_work_packages
    @all_work_packages ||= work_packages.all
  end

  def next_in_same_group?(issue = cached_issue)
    caching_issue issue do |issue|
      !last_issue? &&
        query.group_by_column.value(issue) == query.group_by_column.value(all_work_packages[issue_index + 1])
    end
  end

  def last_issue?(issue = cached_issue)
    caching_issue issue do |_issue|
      issue_index == all_work_packages.size - 1
    end
  end

  def issue_index(issue = cached_issue)
    caching_issue issue do |issue|
      all_work_packages.find_index(issue)
    end
  end

  def grouped_sum_of_issue(column, issue = cached_issue)
    grouped_sum_of column, group_for_issue(issue)
  end

  def grouped_sum_of(column, group)
    sum_of column, group
  end

  def grouped_sums(column)
    all_work_packages
      .map { |wp| query.group_by_column.value(wp) }
      .uniq
      .inject({}) do |group_sums, current_group|
        work_packages_in_current_group = all_work_packages.select { |wp| query.group_by_column.value(wp) == current_group }
        group_sums.merge current_group => sum_of(column, work_packages_in_current_group)
      end
  end

  def total_sum_of(column)
    sum_of(column, all_work_packages)
  end

  def sum_of(column, collection)
    return unless should_be_summed_up?(column)
    # This is a workaround to be able to sum up currency with the redmine_costs plugin
    values = collection.map do |issue|
               column.respond_to?(:real_value) ?
                 column.real_value(issue) :
                 column.value(issue)
             end.select do |value|
               begin
                 next if value.respond_to? :today? or value.is_a? String
                 true if Float(value)
               rescue ArgumentError, TypeError
                 false
               end
             end

    crunch(values.reduce :+)
  end

  def caching_issue(issue)
    @cached_issue = issue unless @cached_issue == issue
    block_given? ? yield(issue) : issue
  end

  def cached_issue
    @cached_issue
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
    return num if num.nil? or num.integer?
    Float(format '%.2f', num.to_f)
  end

  def group_for_issue(issue = @current_issue)
    caching_issue issue do |issue|
      all_work_packages.select do |is|
        query.group_by_column.value(issue) == query.group_by_column.value(is)
      end
    end
  end

  def should_be_summed_up?(column)
    Setting.work_package_list_summable_columns.include?(column.name.to_s)
  end
end
