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

module Migration
  module Utils
    def say_with_time_silently message
      say_with_time message do
        suppress_messages do
          yield
        end
      end
    end

    def update_column_values(table, column_list, updater, conditions)
      updated_rows = []

      select_rows_from_database(table, column_list, conditions).each do |row|
        updated_rows << updater.call(row)
      end

      update_rows_in_database(table, column_list, updated_rows)
    end

    def reset_public_key_sequence_in_postgres(table)
      return unless ActiveRecord::Base.connection.instance_values["config"][:adapter] == "postgresql"
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end

    private

    def select_rows_from_database(table, column_list, conditions)
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
        values = column_list.map {|c| "#{c}=#{quote(row[c])}"}
                            .join(', ')

        update <<-SQL
          UPDATE #{table}
          SET #{values}
          WHERE id = #{row['id']}
        SQL
      end
    end
  end
end
