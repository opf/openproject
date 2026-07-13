# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CustomField::OrderStatements
  ORDER_JOIN_METHOD_BY_FIELD_FORMAT = OpenProject::MultiKeyHash.expand(
    %w[string date bool link] => :join_for_order_by_string_sql,
    "int" => :join_for_order_by_int_sql,
    %w[float calculated_value] => :join_for_order_by_float_sql,
    "list" => :join_for_order_by_list_sql,
    "user" => :join_for_order_by_user_sql,
    "version" => :join_for_order_by_version_sql,
    %w[hierarchy weighted_item_list] => :join_for_order_by_hierarchy_sql
  ).freeze

  # Returns the expression to use in ORDER BY clause to sort objects by their
  # value of the custom field.
  def order_statement
    "cf_order_#{id}.value" if ORDER_JOIN_METHOD_BY_FIELD_FORMAT.key?(field_format)
  end

  # Returns the join statement that is required to sort objects by their value
  # of the custom field.
  def order_join_statement
    method_name = ORDER_JOIN_METHOD_BY_FIELD_FORMAT[field_format]
    send(method_name) if method_name
  end

  # Returns the ORDER BY option defining order of objects without value for the
  # custom field.
  def order_null_handling(asc)
    null_direction = asc ? "FIRST" : "LAST"
    Arel.sql("NULLS #{null_direction}")
  end

  # Returns the expression to use in GROUP BY (and ORDER BY) clause to group
  # objects by their value of the custom field.
  def group_by_statement
    return unless can_be_used_for_grouping?

    order_statement
  end

  # Returns the expression to use in SELECT clause if it differs from one used
  # to group by
  def group_by_select_statement
    return unless %w[list hierarchy weighted_item_list].include?(field_format)

    # MIN needed to not add this column to group by, ANY_VALUE can be used when
    # minimum required PostgreSQL becomes 16
    "MIN(cf_order_#{id}.ids)"
  end

  # Returns the join statement that is required to group objects by their value
  # of the custom field.
  def group_by_join_statement
    return unless can_be_used_for_grouping?

    order_join_statement
  end

  private

  def can_be_used_for_grouping? = field_format.in?(%w[list date bool int float string link hierarchy])

  # Template for all the join statements.
  #
  # For single value custom fields the join ensures single value for every
  # customized object using DISTINCT ON and selecting first value by id of
  # custom value:
  #
  #   LEFT OUTER JOIN (
  #     SELECT DISTINCT ON (cv.customized_id), cv.customized_id, xxx "value"
  #       FROM custom_values cv
  #       WHERE …
  #       ORDER BY cv.customized_id, cv.id
  #   ) cf_order_NNN ON cf_order_NNN.customized_id = …
  #
  # For multi value custom fields the GROUP BY and value aggregate function
  # ensure single value for every customized object:
  #
  #   LEFT OUTER JOIN (
  #     SELECT cv.customized_id, ARRAY_AGG(xxx ORDERY BY yyy) "value"
  #       FROM custom_values cv
  #       WHERE …
  #       GROUP BY cv.customized_id, cv.id
  #   ) cf_order_NNN ON cf_order_NNN.customized_id = …
  #
  def join_for_order_sql(value:, add_select: nil, join: nil, multi_value: false)
    customized_type_condition = OpenProject::SqlSanitization.sanitize(
      "cv.customized_type = ?", self.class.customized_class.base_class.name
    )

    <<~SQL.squish
      LEFT OUTER JOIN (
        SELECT
          #{'DISTINCT ON (cv.customized_id)' unless multi_value}
            cv.customized_id
            , #{value} "value"
            #{", #{add_select}" if add_select}
          FROM #{CustomValue.quoted_table_name} cv
          #{join}
          WHERE #{customized_type_condition}
            AND cv.custom_field_id = #{id}
            AND cv.value IS NOT NULL
            AND cv.value != ''
          #{multi_value ? 'GROUP BY cv.customized_id' : 'ORDER BY cv.customized_id, cv.id'}
      ) cf_order_#{id}
        ON cf_order_#{id}.customized_id = #{self.class.customized_class.quoted_table_name}.id
    SQL
  end

  def join_for_order_by_string_sql = join_for_order_sql(value: "cv.value")

  def join_for_order_by_int_sql = join_for_order_sql(value: "cv.value::decimal(60)")

  def join_for_order_by_float_sql = join_for_order_sql(value: "cv.value::double precision")

  def join_for_order_by_list_sql
    join_for_order_sql(
      value: multi_value? ? "ARRAY_AGG(co.position ORDER BY co.position)" : "co.position",
      add_select: "#{multi_value? ? "ARRAY_TO_STRING(ARRAY_AGG(cv.value ORDER BY co.position), '.')" : 'cv.value'} ids",
      join: "INNER JOIN #{CustomOption.quoted_table_name} co ON co.id = cv.value::bigint",
      multi_value:
    )
  end

  def join_for_order_by_user_sql
    columns_array = "ARRAY[users_for_ordering.lastname, users_for_ordering.firstname, users_for_ordering.mail]"

    join_for_order_sql(
      value: multi_value? ? "ARRAY_AGG(#{columns_array} ORDER BY #{columns_array})" : columns_array,
      join: "INNER JOIN #{User.quoted_table_name} users_for_ordering ON users_for_ordering.id = cv.value::bigint",
      multi_value:
    )
  end

  def join_for_order_by_version_sql
    join_for_order_sql(
      value: if multi_value?
               "array_agg(versions_for_ordering.name ORDER BY versions_for_ordering.name)"
             else
               "versions_for_ordering.name"
             end,
      join: "INNER JOIN #{Version.quoted_table_name} versions_for_ordering ON versions_for_ordering.id = cv.value::bigint",
      multi_value:
    )
  end

  def join_for_order_by_hierarchy_sql
    join_for_order_sql(
      value: multi_value? ? "ARRAY_AGG(item.position_cache ORDER BY item.position_cache)" : "item.position_cache",
      add_select: "#{multi_value? ? "ARRAY_TO_STRING(ARRAY_AGG(cv.value ORDER BY item.position_cache), '.')" : 'cv.value'} ids",
      join: "INNER JOIN #{CustomField::Hierarchy::Item.quoted_table_name} item ON item.id = cv.value::bigint",
      multi_value:
    )
  end
end
