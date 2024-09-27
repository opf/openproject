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

module CustomField::OrderStatements
  # Returns a ORDER BY clause that can used to sort customized
  # objects by their value of the custom field.
  # Returns false, if the custom field can not be used for sorting.
  def order_statements
    case field_format
    when "list"
      [order_by_list_sql]
    when "string", "date", "bool", "link"
      [coalesce_select_custom_value_as_string]
    when "int", "float"
      # Make the database cast values into numeric
      # Postgresql will raise an error if a value can not be casted!
      # CustomValue validations should ensure that it doesn't occur
      [select_custom_value_as_decimal]
    when "user"
      [order_by_user_sql]
    when "version"
      [order_by_version_sql]
    end
  end

  ##
  # Returns the null handling for the given direction
  def null_handling(asc)
    return unless %w[int float].include?(field_format)

    null_direction = asc ? "FIRST" : "LAST"
    Arel.sql("NULLS #{null_direction}")
  end

  # Returns the grouping result
  # which differ for multi-value select fields,
  # because in this case we do want the primary CV values
  def group_by_statement
    return order_statements unless field_format == "list"

    if multi_value?
      # We want to return the internal IDs in the case of grouping
      select_custom_values_as_group
    else
      coalesce_select_custom_value_as_string
    end
  end

  private

  def coalesce_select_custom_value_as_string
    # COALESCE is here to make sure that blank and NULL values are sorted equally
    <<-SQL.squish
      COALESCE(#{select_custom_value_as_string}, '')
    SQL
  end

  def select_custom_value_as_string
    <<-SQL.squish
      (
        SELECT cv_sort.value
          FROM #{CustomValue.quoted_table_name} cv_sort
          WHERE #{cv_sort_only_custom_field_condition_sql}
          LIMIT 1
      )
    SQL
  end

  def select_custom_values_as_group
    <<-SQL.squish
      COALESCE(
        (
          SELECT string_agg(cv_sort.value, '.')
            FROM #{CustomValue.quoted_table_name} cv_sort
            WHERE #{cv_sort_only_custom_field_condition_sql}
              AND cv_sort.value IS NOT NULL
        ),
        ''
      )
    SQL
  end

  def select_custom_value_as_decimal
    <<-SQL.squish
      (
        SELECT CAST(cv_sort.value AS decimal(60,3))
          FROM #{CustomValue.quoted_table_name} cv_sort
          WHERE #{cv_sort_only_custom_field_condition_sql}
            AND cv_sort.value <> ''
            AND cv_sort.value IS NOT NULL
          LIMIT 1
      )
    SQL
  end

  def order_by_list_sql
    columns = multi_value? ? "array_agg(co_sort.position ORDER BY co_sort.position)" : "co_sort.position"
    limit = multi_value? ? "" : "LIMIT 1"

    <<-SQL.squish
      (
        SELECT #{columns}
          FROM #{CustomOption.quoted_table_name} co_sort
          INNER JOIN #{CustomValue.quoted_table_name} cv_sort
            ON cv_sort.value IS NOT NULL AND cv_sort.value != '' AND co_sort.id = cv_sort.value::bigint
          WHERE #{cv_sort_only_custom_field_condition_sql}
          #{limit}
      )
    SQL
  end

  def order_by_user_sql
    columns_array = "ARRAY[cv_user.lastname, cv_user.firstname, cv_user.mail]"

    columns = multi_value? ? "array_agg(#{columns_array} ORDER BY #{columns_array})" : columns_array
    limit = multi_value? ? "" : "LIMIT 1"

    <<-SQL.squish
      (
        SELECT #{columns}
          FROM #{User.quoted_table_name} cv_user
          INNER JOIN #{CustomValue.quoted_table_name} cv_sort
            ON cv_sort.value IS NOT NULL AND cv_sort.value != '' AND cv_user.id = cv_sort.value::bigint
          WHERE #{cv_sort_only_custom_field_condition_sql}
          #{limit}
      )
    SQL
  end

  def order_by_version_sql
    columns = multi_value? ? "array_agg(cv_version.name ORDER BY cv_version.name)" : "cv_version.name"
    limit = multi_value? ? "" : "LIMIT 1"

    <<-SQL.squish
      (
        SELECT #{columns}
          FROM #{Version.quoted_table_name} cv_version
          INNER JOIN #{CustomValue.quoted_table_name} cv_sort
            ON cv_sort.value IS NOT NULL AND cv_sort.value != '' AND cv_version.id = cv_sort.value::bigint
          WHERE #{cv_sort_only_custom_field_condition_sql}
          #{limit}
      )
    SQL
  end

  def cv_sort_only_custom_field_condition_sql
    <<-SQL.squish
      cv_sort.customized_type='#{self.class.customized_class.name}'
      AND cv_sort.customized_id=#{self.class.customized_class.quoted_table_name}.id
      AND cv_sort.custom_field_id=#{id}
    SQL
  end
end
