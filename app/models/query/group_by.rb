#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module ::Query::Grouping
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

  def groups_grouped_by_column
    # Rails will raise an (unexpected) RecordNotFound if there's only a nil group value
    WorkPackage
      .group(query.group_by_statement)
      .visible
      .includes(all_includes)
      .joins(all_filter_joins)
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
    # Because of multi select cfs we might end up having overlapping groups
    # (e.g group "1" and group "1.3" and group "3" which represent concatenated ids).
    # This can result in us having ids in the keys array multiple times (e.g. ["1", "1", "3", "3"]).
    # If we were to use the keys array with duplicates to find the actual custom options,
    # AR would throw an error as the number of records returned does not match the number
    # of ids searched for.
    custom_field.custom_options.find(keys.flatten.uniq).group_by { |o| o.id.to_s }
  end

  def transform_custom_field_keys(custom_field, groups)
    groups.transform_keys { |key| custom_field.cast_value(key) }
  end
  # Returns the SQL sort order that should be prepended for grouping
  def group_by_sort_order
    if query.grouped? && (column = query.group_by_column)
      aliases = include_aliases

      Array(column.sortable).map do |s|
        aliased_group_by_sort_order(s, order_for_group_by(column), aliases[column.name])
      end.join(',')
    end
  end

  def aliased_group_by_sort_order(sortable, order, alias_name)
    if alias_name
      "#{alias_name}.#{sortable} #{order}"
    else
      "#{sortable} #{order}"
    end
  end

  ##
  # Retrieve the defined order for the group by
  # IF it occurs in the sort criteria
  def order_for_group_by(column)
    sort_entry = query.sort_criteria.detect { |column, _dir| column == query.group_by }
    sort_entry&.last || column.default_order
  end
end
