#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module ::Query::Results::GroupBy
  # Returns the work package count by group or nil if query is not grouped
  def work_package_count_by_group
    @work_package_count_by_group ||= if query.grouped?
                                       r = group_counts_by_group

                                       transform_group_keys(r)
                                     end
  rescue ::ActiveRecord::StatementInvalid => e
    raise ::Query::StatementInvalid.new(e.message)
  end

  def work_package_count_for(group)
    work_package_count_by_group[group]
  end

  private

  def group_counts_by_group
    work_packages_with_includes_for_count
      .group(group_by_for_count)
      .visible
      .references(:statuses, :projects)
      .where(query.statement)
      .order(order_for_count)
      .pluck(*pluck_for_count)
      .to_h
  end

  def work_packages_with_includes_for_count
    WorkPackage
      .includes(all_includes)
      .joins(all_filter_joins)
  end

  def group_by_for_count
    Array(query.group_by_statement).map { |statement| Arel.sql(statement) } +
      [Arel.sql(group_by_sort(order: false))]
  end

  def pluck_for_count
    Array(query.group_by_statement).map { |statement| Arel.sql(statement) } +
      [Arel.sql('COUNT(DISTINCT "work_packages"."id")')]
  end

  def order_for_count
    Arel.sql(group_by_sort)
  end

  def transform_group_keys(groups)
    if query.group_by_column.is_a?(Queries::WorkPackages::Selects::CustomFieldSelect)
      transform_custom_field_keys(groups)
    else
      transform_property_keys(groups)
    end
  end

  def transform_custom_field_keys(groups)
    custom_field = query.group_by_column.custom_field

    if custom_field.list?
      transform_list_custom_field_keys(custom_field, groups)
    else
      transform_single_custom_field_keys(custom_field, groups)
    end
  end

  def transform_list_custom_field_keys(custom_field, groups)
    options = custom_options_for_keys(custom_field, groups)

    groups.transform_keys do |key|
      if custom_field.multi_value?
        key.split(".").map do |subkey|
          options[subkey].first
        end
      else
        options[key] ? options[key].first : nil
      end
    end
  end

  def custom_options_for_keys(custom_field, groups)
    keys = groups.keys.map { |k| k.split(".") }
    # Because of multi select cfs we might end up having overlapping groups
    # (e.g group "1" and group "1.3" and group "3" which represent concatenated ids).
    # This can result in us having ids in the keys array multiple times (e.g. ["1", "1", "3", "3"]).
    # If we were to use the keys array with duplicates to find the actual custom options,
    # AR would throw an error as the number of records returned does not match the number
    # of ids searched for.
    custom_field.custom_options.find(keys.flatten.uniq).group_by { |o| o.id.to_s }
  end

  def transform_single_custom_field_keys(custom_field, groups)
    groups.transform_keys { |key| custom_field.cast_value(key) }
  end

  def transform_property_keys(groups)
    association = WorkPackage.reflect_on_all_associations.detect { |a| a.name == query.group_by_column.name.to_sym }

    if association
      transform_association_property_keys(association, groups)
    else
      groups
    end
  end

  def transform_association_property_keys(association, groups)
    ar_keys = association.class_name.constantize.find(groups.keys.compact)

    groups.transform_keys do |key|
      ar_keys.detect { |ar_key| ar_key.id == key }
    end
  end

  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort(order: true)
    if query.grouped? && (column = query.group_by_column)
      alias_name = include_aliases[column.name]
      columns_hash = columns_hash_for(alias_name ? column.association : nil)
      Array(column.sortable).map do |s|
        direction = order ? order_for_group_by(column) : nil

        aliased_group_by_sort_order(alias_name, s, columns_hash, direction)
      end.join(", ")
    end
  end

  def aliased_group_by_sort_order(alias_name, sortable, columns_hash, order = nil)
    column = if alias_name
               expand_association_column(sortable, alias_name)
             else
               sortable
             end

    column = case_insensitive_condition(sortable, column, columns_hash)

    if order
      "#{column} #{order}"
    else
      column
    end
  end

  ##
  # Retrieve the defined order for the group by
  # IF it occurs in the sort criteria
  def order_for_group_by(column)
    sort_entry = query.sort_criteria.detect { |c, _dir| c == query.group_by }
    order = sort_entry&.last || column.default_order

    "#{order} #{column.null_handling(order == 'asc')}"
  end
end
