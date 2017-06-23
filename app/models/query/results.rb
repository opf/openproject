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
    WorkPackage
      .visible
      .where(query.statement)
      .where(options[:conditions])
      .includes(all_includes)
      .order(order_option)
      .references(:projects)
  end

  # Same as :work_packages, but returns a result sorted by the sort_criteria defined in the query.
  # Note: It escapes me, why this is not the default behaviour.
  # If there is a reason: This is a somewhat DRY way of using the sort criteria.
  # If there is no reason: The :work_package method can die over time and be replaced by this one.
  def sorted_work_packages
    work_packages.order(sort_criteria_sql)
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
    order_option = [group_by_sort_order].reject(&:blank?).join(', ')
    order_option = nil if order_option.blank?

    order_option
  end

  private

  def all_includes
    (%i(status project) +
      includes_for_columns(include_columns) +
      (options[:include] || [])).uniq
  end

  def includes_for_columns(column_names)
    column_names = Array(column_names)
    (WorkPackage.reflections.keys.map(&:to_sym) & column_names.map(&:to_sym))
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

    if column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn) && column.custom_field.list?
      transform_list_group_by_keys(column.custom_field, groups)
    elsif column.is_a?(Queries::WorkPackages::Columns::CustomFieldColumn)
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

  ##
  # Returns the columns that need to be included to allow:
  # * sorting
  # * grouping
  def include_columns
    columns = query.sort_criteria.map { |x| x.first.to_sym }

    columns << query.group_by.to_sym if query.group_by

    columns.uniq
  end

  def sort_criteria_sql
    criteria = SortHelper::SortCriteria.new
    criteria.available_criteria = aliased_sorting_by_column_name
    criteria.criteria = query.sort_criteria
    criteria.to_sql
  end

  def aliased_sorting_by_column_name
    sorting_by_column_name = query.sortable_key_by_column_name

    aliases = include_aliases

    reflection_includes.each do |inc|
      sorting_by_column_name[inc.to_s] = Array(sorting_by_column_name[inc.to_s]).map { |column| "#{aliases[inc]}.#{column}" }
    end

    sorting_by_column_name
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if query.grouped? && (column = query.group_by_column)
      aliases = include_aliases

      Array(column.sortable).map do |s|
        aliased_group_by_sort_order(s, column, aliases[column.name])
      end.join(',')
    end
  end

  def aliased_group_by_sort_order(sortable, column, alias_name)
    if alias_name
      "#{alias_name}.#{sortable} #{column.default_order}"
    else
      "#{sortable} #{column.default_order}"
    end
  end

  # To avoid naming conflicts, joined tables are aliased if they are joined
  # more than once. Here, joining tables that are referenced by multiple
  # columns are of particular interest.
  #
  # Mirroring the way AR creates aliases for included/joined tables: Normally,
  # included/joined associations are not aliased and as such, they simply use
  # the table name. But if an association is joined/included that relies on a
  # table which an already joined/included association also relies upon, that
  # name is already taken in the DB query. Therefore, the #alias_candidate
  # method is used which will concatenate the pluralized association name with
  # the table name the association is defined for.
  #
  # There is no handling for cases when the same association is joined/included
  # multiple times as the rest of the code should prevent that.
  def include_aliases
    counts = Hash.new do |h, key|
      h[key] = 0
    end

    reflection_includes.each_with_object({}) do |inc, hash|
      reflection = WorkPackage.reflections[inc.to_s]
      table_name = reflection.klass.table_name

      hash[inc] = reflection_alias(reflection, counts[table_name])

      counts[table_name] += 1
    end
  end

  def reflection_includes
    WorkPackage.reflections.keys.map(&:to_sym) & all_includes.map(&:to_sym)
  end

  def reflection_alias(reflection, count)
    if count.zero?
      reflection.klass.table_name
    else
      reflection.alias_candidate(WorkPackage.table_name)
    end
  end
end
