#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
module ::Query::Sums
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
    caching_issue issue do |issue|
      issue_index == all_work_packages.size - 1
    end
  end

  def issue_index(issue = cached_issue)
    caching_issue issue do |issue|
      all_work_packages.find_index(issue)
    end
  end

  def grouped_sum_of(column, issue = cached_issue)
    sum_of(column, group_for_issue(issue))
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
    Float(format "%.2f", num.to_f)
  end

  def group_for_issue(issue = @current_issue)
    caching_issue issue do |issue|
      all_work_packages.select do |is|
        query.group_by_column.value(issue) == query.group_by_column.value(is)
      end
    end
  end

  def should_be_summed_up?(column)
    Setting.issue_list_summable_columns.include?(column.name.to_s)
  end
end
