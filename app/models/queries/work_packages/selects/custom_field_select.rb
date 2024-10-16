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

class Queries::WorkPackages::Selects::CustomFieldSelect < Queries::WorkPackages::Selects::WorkPackageSelect
  def initialize(custom_field)
    super

    @cf = custom_field

    @name = custom_field.column_name.to_sym
    @sortable = custom_field.order_statement
    @sortable_join = custom_field.order_join_statement
    @groupable = custom_field.group_by_statement
    @groupable_join = custom_field.group_by_join_statement
    @groupable_select = custom_field.group_by_select_statement
    @summable = summable_statement
  end

  def caption
    @cf.name
  end

  def null_handling(...) = custom_field.order_null_handling(...)

  def custom_field
    @cf
  end

  def value(work_package)
    work_package.formatted_custom_value_for(@cf.id)
  end

  def self.instances(context = nil)
    if context
      context.all_work_package_custom_fields
    else
      WorkPackageCustomField.all
    end
      .reject { |cf| cf.field_format == "text" }
      .map { |cf| new(cf) }
  end

  private

  def summable_scope(query)
    WorkPackage
      .where(id: query.results.work_packages)
      .left_joins(:custom_values)
      .where(custom_values: { custom_field: })
      .where.not(custom_values: { value: nil })
      .where.not(custom_values: { value: "" })
  end

  def summable_select_statement
    if custom_field.field_format == "int"
      "COALESCE(SUM(#{CustomValue.quoted_table_name}.value::BIGINT)::BIGINT, 0) #{name}"
    else
      "COALESCE(ROUND(SUM(#{CustomValue.quoted_table_name}.value::NUMERIC), 2)::FLOAT, 0.0) #{name}"
    end
  end

  def summable_statement
    if %w[float int].include?(custom_field.field_format)
      select = summable_select_statement

      ->(query, grouped) {
        Queries::WorkPackages::Selects::WorkPackageSelect
          .scoped_column_sum(summable_scope(query), select, grouped:, query:)
      }
    else
      false
    end
  end
end
