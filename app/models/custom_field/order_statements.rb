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

module CustomField::OrderStatements
  # Returns a ORDER BY clause that can used to sort customized
  # objects by their value of the custom field.
  # Returns false, if the custom field can not be used for sorting.
  def order_statements
    case field_format
    when 'string', 'text', 'list', 'date', 'bool'
      if multi_value?
        [select_custom_values_as_group]
      else
        # COALESCE is here to make sure that blank and NULL values are sorted equally
        [
          <<-SQL
          COALESCE(#{select_custom_value_as_string}, '')
          SQL
        ]
      end
    when 'int', 'float'
      # Make the database cast values into numeric
      # Postgresql will raise an error if a value can not be casted!
      # CustomValue validations should ensure that it doesn't occur
      [
        select_custom_value_as_decimal
      ]
    when 'user'
      [
        order_by_user_sql('lastname'),
        order_by_user_sql('firstname'),
        order_by_user_sql('id')
      ]
    end
  end

  private

  def select_custom_value_as_string
    <<-SQL
    (SELECT cv_sort.value FROM #{CustomValue.table_name} cv_sort
        WHERE cv_sort.customized_type='#{self.class.customized_class.name}'
        AND cv_sort.customized_id=#{self.class.customized_class.table_name}.id
        AND cv_sort.custom_field_id=#{id} LIMIT 1)
    SQL
  end

  def select_custom_values_as_group
    <<-SQL
      COALESCE((SELECT string_agg(cv_sort.value, '.') FROM #{CustomValue.table_name} cv_sort
        WHERE cv_sort.customized_type='#{self.class.customized_class.name}'
          AND cv_sort.customized_id=#{self.class.customized_class.table_name}.id
          AND cv_sort.custom_field_id=#{id}
          AND cv_sort.value IS NOT NULL), '')
    SQL
  end

  def select_custom_value_as_decimal
    <<-SQL
    (SELECT CAST(cv_sort.value AS decimal(60,3)) FROM #{CustomValue.table_name} cv_sort
      WHERE cv_sort.customized_type='#{self.class.customized_class.name}'
      AND cv_sort.customized_id=#{self.class.customized_class.table_name}.id
      AND cv_sort.custom_field_id=#{id}
      AND cv_sort.value <> ''
      AND cv_sort.value IS NOT NULL
    LIMIT 1)
    SQL
  end

  def order_by_user_sql(column)
    <<-SQL
    (SELECT #{column} FROM #{User.table_name} cv_user
     WHERE cv_user.id = #{select_custom_value_as_decimal}
     LIMIT 1)
    SQL
  end
end
