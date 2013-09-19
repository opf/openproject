#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'yaml'

class MigrateQueryTrackerReferencesToType < ActiveRecord::Migration
  COLUMNS = ['filters', 'column_names', 'sort_criteria', 'group_by']
  KEY = { 'tracker_id' => 'type_id', 'tracker' => 'type' }

  def up
    update_column_values_with_keys(KEY)
  end

  def down
    update_column_values_with_keys(KEY.invert)
  end

  private

  def update_row_values
    Proc.new do |keys, row|
      columns.each do |column|
        unless row[column].nil?
          value = YAML.load row[column]

          if value.is_a? Array
            value.collect! do |e| 
              if e.is_a? Array
                e.collect! {|v| keys.has_key? v ? keys[v] : v}
              else
                (keys.has_key? e.to_s) ? keys[e.to_s].to_sym : e
              end
            end
          elsif value.is_a? Hash
            keys.select {|k| value[k.to_s]}
                .each_pair {|k, v| value[v] = value.delete k}
          end

          row[column] = YAML.dump value
        end
      end

      row
    end
  end

  def update_column_values_with_keys(keys)
    filter = COLUMNS.join(" LIKE '%tracker%' OR ") + " LIKE '%tracker%'"

    update_column_values('queries', COLUMNS, update_row_values, keys, filter)
  end


  def update_column_values(table, column_list, updater, keys, conditions)
    updated_rows = []
    
    select_rows_for_update(table, column_list, conditions).each do |row|
      updated_rows << updater.call(keys, row)
    end

    update_rows_in_database(table, column_list, updated_rows)
  end

  def select_rows_for_update(table, column_list, conditions)
    columns = (column_list.nil?) ? '' : ', ' + column_list.join(', ')
    from_clause = table
    where_clause =  conditions.nil? ? '1 = 1' : conditions

    select_all <<-SQL
      SELECT id#{columns}
      FROM #{from_clause}
      WHERE #{where_clause}
    SQL
  end

  def update_rows_in_database(table, column_list, updated_rows)
    columns = (column_list.nil?) ? '' : column_list.join(', ')

    updated_rows.each do |row|
      values = column_list.map {|c| "#{c}=#{connection.quote(row[c])}"}
                          .join(', ')

      insert = <<-SQL
        UPDATE #{table}
        SET #{values}
        WHERE id = #{row['id']}
      SQL

      connection.execute(insert)
    end
  end
end
