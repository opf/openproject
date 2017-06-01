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

class ::Query::Results
  include Sums
  include Redmine::I18n

  attr_accessor :options,
                :query

  # Valid options are :order, :include, :conditions
  def initialize(query, options = {})
    self.options = options
    self.query = query
  end

  # Returns the work package count
  def work_package_count
    WorkPackage.visible
               .includes(:status, :project)
               .where(query.statement)
               .references(:statuses, :projects)
               .count
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  # Returns the work package count by group or nil if query is not grouped
  def work_package_count_by_group
    @work_package_count_by_group ||= begin
      if query.grouped?
        r = groups_grouped_by_column

        transform_group_keys(r)
      end
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def work_package_count_for(group)
    work_package_count_by_group[group]
  end

  def work_packages
    includes = ([:status, :project] +
      includes_for_columns(query.involved_columns) + (options[:include] || [])).uniq

    WorkPackage
      .visible
      .where(query.statement)
      .where(options[:conditions])
      .includes(includes)
      .joins((query.group_by_column ? query.group_by_column.join : nil))
      .order(order_option)
      .references(:projects)
  end

  # Same as :work_packages, but returns a result sorted by the sort_criteria defined in the query.
  # Note: It escapes me, why this is not the default behaviour.
  # If there is a reason: This is a somewhat DRY way of using the sort criteria.
  # If there is no reason: The :work_package method can die over time and be replaced by this one.
  def sorted_work_packages
    work_packages.order(query.sort_criteria_sql)
  end

  def versions
    scope = Version
            .visible
            .where(options[:conditions])

    if query.project
      scope.where(query.project_limiting_filter.where)
    end

    scope
  end

  def column_total_sums
    query.columns.map { |column| total_sum_of(column) }
  end

  def all_total_sums
    query.available_columns.select { |column|
      column.summable? && Setting.work_package_list_summable_columns.include?(column.name.to_s)
    }.inject({}) { |result, column|
      sum = total_sum_of(column)
      result[column] = sum unless sum.nil?
      result
    }
  end

  def all_sums_for_group(group)
    return nil unless query.grouped?

    group_work_packages = work_packages.select { |wp| query.group_by_column.value(wp) == group }
    query.available_columns.inject({}) { |result, column|
      sum = sum_of(column, group_work_packages)
      result[column] = sum unless sum.nil?
      result
    }
  end

  def column_group_sums
    query.group_by_column && query.columns.map { |column| grouped_sums(column) }
  end

  def order_option
    order_option = [query.group_by_sort_order, options[:order]].reject(&:blank?).join(', ')
    order_option = nil if order_option.blank?

    order_option
  end

  private

  def includes_for_columns(column_names)
    column_names = Array(column_names)
    includes = (WorkPackage.reflections.keys.map(&:to_sym) & column_names.map(&:to_sym))

    if column_names.any? { |column| custom_field_column?(column) }
      includes << { custom_values: :custom_field }
    end

    includes
  end

  def custom_field_column?(name)
    name.to_s =~ /\Acf_\d+\z/
  end

  def groups_grouped_by_column
    # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
    WorkPackage
      .group(query.group_by_statement)
      .visible
      .includes(:status, :project)
      .references(:statuses, :projects)
      .where(query.statement)
      .count
  rescue ActiveRecord::RecordNotFound
    { nil => work_package_count }
  end

  def transform_group_keys(groups)
    column = query.group_by_column

    if column.is_a?(QueryCustomFieldColumn) && column.custom_field.list?
      transform_list_group_by_keys(column.custom_field, groups)
    elsif column.is_a?(QueryCustomFieldColumn)
      transform_custom_field_keys(column.custom_field, groups)
    else
      groups
    end
  end

  def transform_list_group_by_keys(custom_field, groups)
    options = custom_options_for_keys(custom_field, groups)

    groups.transform_keys do |key|
      if custom_field.multi_value?
        key.split('.').map do |subkey|
          options[subkey].first
        end
      else
        options[key] ? options[key].first : nil
      end
    end
  end

  def custom_options_for_keys(custom_field, groups)
    keys = groups.keys.map { |k| k.split('.') }
    custom_field.custom_options.find(keys.flatten).group_by { |o| o.id.to_s }
  end

  def transform_custom_field_keys(custom_field, groups)
    groups.transform_keys { |key| custom_field.cast_value(key) }
  end
end
