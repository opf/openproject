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

module Migration
  module Utils
    UpdateResult = Struct.new(:row, :updated)

    def say_with_time_silently(message)
      say_with_time message do
        suppress_messages do
          yield
        end
      end
    end

    def filter(columns, terms)
      column_filters = []

      columns.each do |column|
        filters = terms.map { |term| "#{column} LIKE '%#{term}%'" }

        column_filters << "(#{filters.join(' OR ')})"
      end

      column_filters.join(' OR ')
    end

    def update_column_values(table, column_list, updater, conditions)
      update_column_values_and_journals(table, column_list, updater, false, conditions)
    end

    def update_column_values_and_journals(table, column_list, updater, update_journal, conditions)
      processed_rows = []

      select_rows_from_database(table, column_list, conditions).each do |row|
        processed_rows << updater.call(row)
      end

      updated_rows = processed_rows.select(&:updated)

      update_rows_in_database(table, column_list, updated_rows.map(&:row))

      update_journals(table, updated_rows) if update_journal
    end

    def reset_public_key_sequence_in_postgres(table)
      return unless ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
      ActiveRecord::Base.connection.reset_pk_sequence!(table)
    end

    def postgres?
      ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'postgresql'
    end

    def mysql?
      ActiveRecord::Base.connection.instance_values['config'][:adapter] == 'mysql2'
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
        values = column_list.map { |c| "#{c}=#{quote(row[c])}" }
                 .join(', ')

        update <<-SQL
          UPDATE #{table}
          SET #{values}
          WHERE id = #{row['id']}
        SQL
      end
    end

    def update_journals(table, updated_rows)
      created_journals = {}

      updated_ids = updated_rows.map { |r| r.row['id'] }
      journal_table = "#{table.singularize}_journals"
      journable_type = table.classify

      updated_ids.each do |id|
        created_journals[id] = insert <<-SQL
          INSERT INTO journals (journable_id, journable_type, user_id, created_at, version, activity_type)
          SELECT journable_id, journable_type, #{system_user_id}, NOW(), MAX(version) + 1, activity_type
          FROM journals
          WHERE journable_type = '#{journable_type}' AND journable_id = #{id}
          GROUP BY journable_id, journable_type, activity_type
        SQL
      end

      journal_table_columns = journal_table_columns(journal_table)

      insert <<-SQL
        INSERT INTO #{journal_table} (journal_id, #{journal_table_columns.join(', ')})
        SELECT j.id AS journal_id, #{journal_table_columns.map { |c| "w.#{c}" }.join(', ')}
        FROM journals AS j JOIN #{table} AS w ON (j.journable_id = w.id)
        WHERE journable_type = '#{journable_type}'
          AND j.id NOT IN (SELECT journal_id FROM work_package_journals)
      SQL
    end

    def system_user_id
      @system_user_id ||= User.system.id
    end

    def journal_table_columns(table)
      "Journal::#{table.classify}".constantize.column_names - ['id', 'journal_id']
    end
  end
end
