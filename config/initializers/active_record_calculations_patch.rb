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

warning_message = <<END



OpenProject is overwriting ActiveRecord::Calculations#execute_grouped_calculation.
The code copied was taken from rails 4.2.4.
Check, if the patch is still needed and if it is, check that it is working.



END
warn warning_message if Rails.gem_version >= Gem::Version.new('4.3')

module ActiveRecord
  module Calculations
    # Overwriting to profit from https://github.com/rails/rails/pull/21950
    def execute_grouped_calculation(operation, column_name, distinct) #:nodoc:
      group_attrs = group_values

      if group_attrs.first.respond_to?(:to_sym)
        association  = @klass._reflect_on_association(group_attrs.first)
        associated   = group_attrs.size == 1 && association && association.belongs_to? # only count belongs_to associations
        group_fields = Array(associated ? association.foreign_key : group_attrs)
      else
        group_fields = group_attrs
      end
      # This line was added in order to fix ambiguous matches in group by
      # It is copied over from
      # https://github.com/rails/rails/pull/21950
      group_fields = arel_columns(group_fields)
      # End of copied over code

      group_aliases = group_fields.map { |field|
        column_alias_for(field)
      }
      group_columns = group_aliases.zip(group_fields).map { |aliaz,field|
        [aliaz, field]
      }

      group = group_fields

      if operation == 'count' && column_name == :all
        aggregate_alias = 'count_all'
      else
        aggregate_alias = column_alias_for([operation, column_name].join(' '))
      end

      select_values = [
        operation_over_aggregate_column(
          aggregate_column(column_name),
          operation,
          distinct).as(aggregate_alias)
      ]
      select_values += select_values unless having_values.empty?

      select_values.concat group_fields.zip(group_aliases).map { |field,aliaz|
        if field.respond_to?(:as)
          field.as(aliaz)
        else
          "#{field} AS #{aliaz}"
        end
      }

      relation = except(:group)
      relation.group_values  = group
      relation.select_values = select_values

      calculated_data = @klass.connection.select_all(relation, nil, relation.arel.bind_values + bind_values)

      if association
        key_ids     = calculated_data.collect { |row| row[group_aliases.first] }
        key_records = association.klass.base_class.find(key_ids)
        key_records = Hash[key_records.map { |r| [r.id, r] }]
      end

      Hash[calculated_data.map do |row|
        key = group_columns.map { |aliaz, col_name|
          column = calculated_data.column_types.fetch(aliaz) do
            type_for(col_name)
          end
          type_cast_calculated_value(row[aliaz], column)
        }
        key = key.first if key.size == 1
        key = key_records[key] if associated

        column_type = calculated_data.column_types.fetch(aggregate_alias) { type_for(column_name) }
        [key, type_cast_calculated_value(row[aggregate_alias], column_type, operation)]
      end]
    end
  end
end
