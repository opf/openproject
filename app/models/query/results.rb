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
    WorkPackage.includes(:status, :project).where(query.statement).count
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  # Returns the work package count by group or nil if query is not grouped
  def work_package_count_by_group
    @work_package_count_by_group ||= begin
      r = nil
      if query.grouped?
        begin
          # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
          r = WorkPackage.group(query.group_by_statement)
              .includes(:status, :project)
              .where(query.statement)
              .references(:statuses, :projects)
              .count
        rescue ActiveRecord::RecordNotFound
          r = { nil => work_package_count }
        end
        c = query.group_by_column
        if c.is_a?(QueryCustomFieldColumn)
          r = r.keys.inject({}) { |h, k| h[c.custom_field.cast_value(k)] = r[k]; h }
        end
      end
      r
    end
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def work_package_count_for(group)
    work_package_count_by_group[group]
  end

  def work_packages
    WorkPackage.where(::Query.merge_conditions(query.statement, options[:conditions]))
      .includes([:status, :project] + (options[:include] || []).uniq)
      .includes(includes_for_columns(query.involved_columns))
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
    Version.includes(:project)
      .where(::Query.merge_conditions(query.project_statement, options[:conditions]))
      .references(:projects)
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def column_total_sums
    query.columns.map { |column| total_sum_of(column) }
  end

  def all_total_sums
    query.available_columns.inject({}) { |result, column|
      sum = total_sum_of(column)
      result[column] = sum unless sum.nil?
      result
    }
  end

  def all_sums_for_group(group)
    return nil unless query.grouped?

    group_work_packages = all_work_packages.select { |wp| query.group_by_column.value(wp) == group }
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
    includes = (WorkPackage.reflections.keys & column_names.map(&:to_sym))

    if column_names.any? { |column| custom_field_column?(column) }
      includes << { custom_values: :custom_field }
    end

    includes
  end

  def custom_field_column?(name)
    name.to_s =~ /\Acf_\d+\z/
  end
end
