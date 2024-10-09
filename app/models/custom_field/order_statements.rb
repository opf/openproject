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
  # Returns the expression to use in ORDER BY clause to sort objects by their
  # value of the custom field.
  def order_statement
    case field_format
    when "string", "date", "bool", "link", "int", "float", "list", "user", "version"
      "cf_order_#{id}.value"
    end
  end

  # Returns the join statement that is required to sort objects by their value
  # of the custom field.
  def order_join_statement
    case field_format
    when "string", "date", "bool", "link"
      join_for_order_by_string_sql
    when "int"
      join_for_order_by_int_sql
    when "float"
      join_for_order_by_float_sql
    when "list"
      join_for_order_by_list_sql
    when "user"
      join_for_order_by_user_sql
    when "version"
      join_for_order_by_version_sql
    end
  end

  # Returns the ORDER BY option defining order of objects without value for the
  # custom field.
  def order_null_handling(asc)
    return unless %w[int float string date bool link].include?(field_format)

    null_direction = asc ? "FIRST" : "LAST"
    Arel.sql("NULLS #{null_direction}")
  end

  # Returns the expression to use in GROUP BY (and ORDER BY) clause to group
  # objects by their value of the custom field.
  def group_by_statement
    return unless field_format.in?(%w[list date bool int float string link])

    order_statement
  end

  # Returns the join statement that is required to group objects by their value
  # of the custom field.
  def group_by_join_statement
    return join_for_group_by_list_sql if field_format == "list"

    order_join_statement
  end

  private

  def join_for_order_by_string_sql
    <<-SQL.squish
      LEFT OUTER JOIN (
        SELECT DISTINCT ON (cv.customized_id) cv.customized_id, cv.value "value"
          FROM #{CustomValue.quoted_table_name} cv
          WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
            AND cv.custom_field_id = #{id}
            AND cv.value IS NOT NULL
            AND cv.value != ''
          ORDER BY cv.customized_id, cv.id
      ) cf_order_#{id}
        ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
    SQL
  end

  def join_for_order_by_int_sql
    <<-SQL.squish
      LEFT OUTER JOIN (
        SELECT DISTINCT ON (cv.customized_id) cv.customized_id, cv.value::decimal(60) "value"
          FROM #{CustomValue.quoted_table_name} cv
          WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
            AND cv.custom_field_id = #{id}
            AND cv.value IS NOT NULL
            AND cv.value != ''
          ORDER BY cv.customized_id, cv.id
      ) cf_order_#{id}
        ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
    SQL
  end

  def join_for_order_by_float_sql
    <<-SQL.squish
      LEFT OUTER JOIN (
        SELECT DISTINCT ON (cv.customized_id) cv.customized_id, cv.value::double precision "value"
          FROM #{CustomValue.quoted_table_name} cv
          WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
            AND cv.custom_field_id = #{id}
            AND cv.value IS NOT NULL
            AND cv.value != ''
          ORDER BY cv.customized_id, cv.id
      ) cf_order_#{id}
        ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
    SQL
  end

  def join_for_order_by_list_sql
    if multi_value?
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT cv.customized_id, array_agg(co.position ORDER BY co.position) "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{CustomOption.quoted_table_name} co
              ON co.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            GROUP BY cv.customized_id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    else
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT DISTINCT ON (cv.customized_id) cv.customized_id, co.position "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{CustomOption.quoted_table_name} co
              ON co.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            ORDER BY cv.customized_id, cv.id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    end
  end

  def join_for_group_by_list_sql
    if multi_value?
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT cv.customized_id, array_to_string(array_agg(cv.value ORDER BY co.position), '.') "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{CustomOption.quoted_table_name} co
              ON co.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            GROUP BY cv.customized_id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    else
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT DISTINCT ON (cv.customized_id) cv.customized_id, cv.value "value"
            FROM #{CustomValue.quoted_table_name} cv
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            ORDER BY cv.customized_id, cv.id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    end
  end

  def join_for_order_by_user_sql
    columns_array = "ARRAY[users.lastname, users.firstname, users.mail]"

    if multi_value?
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT cv.customized_id, ARRAY_AGG(#{columns_array} ORDER BY #{columns_array}) "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{User.quoted_table_name} users
              ON users.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            GROUP BY cv.customized_id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    else
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT DISTINCT ON (cv.customized_id) cv.customized_id, #{columns_array} "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{User.quoted_table_name} users
              ON users.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            ORDER BY cv.customized_id, cv.id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    end
  end

  def join_for_order_by_version_sql
    if multi_value?
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT cv.customized_id, array_agg(versions.name ORDER BY versions.name) "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{Version.quoted_table_name} versions
              ON versions.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            GROUP BY cv.customized_id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    else
      <<-SQL.squish
        LEFT OUTER JOIN (
          SELECT DISTINCT ON (cv.customized_id) cv.customized_id, versions.name "value"
            FROM #{CustomValue.quoted_table_name} cv
            INNER JOIN #{Version.quoted_table_name} versions
              ON versions.id = cv.value::bigint
            WHERE cv.customized_type = #{CustomValue.connection.quote(self.class.customized_class.name)}
              AND cv.custom_field_id = #{id}
              AND cv.value IS NOT NULL
              AND cv.value != ''
            ORDER BY cv.customized_id, cv.id
        ) cf_order_#{id}
          ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
      SQL
    end
  end
end
