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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Journals::CreateService
  # Journals the rows returned by `current_rows_sql` into the table of `journal_class`, one row per source row.
  # Every column of the journal table is journaled, so adding a column there journals it. The `reference_column`
  # holds the id of the source row; every other column is copied from the source column of the same name.
  # The journal table needs a unique index on `journal_id` and the `reference_column`.
  class JournalTableAssociation < Association
    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              journal_table_name,
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:)
        INSERT INTO
          #{journal_table_name} (#{sink_columns_sql})
        SELECT
          #{source_columns_sql}
        FROM (#{current_rows_sql}) current_rows
        WHERE
          #{only_if_created_sql}
        #{upsert_sql}
      SQL
    end

    def changes_sql
      sanitize(<<~SQL, journable_id:) # rubocop:disable Rails/SquishedSQLHeredocs -- squish breaks normalize_newlines_sql
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          #{journal_table_name}
        ON
          #{journal_table_name}.journal_id = max_journals.id
        FULL JOIN
          (#{current_rows_sql}) current_rows
        ON
          current_rows.id = #{journal_table_name}.#{reference_column}
        WHERE
          #{changed_columns_condition_sql}
      SQL
    end

    private

    def journal_class
      raise SubclassResponsibilityError
    end

    def reference_column
      raise SubclassResponsibilityError
    end

    # Selects the rows to journal, scoped to `:journable_id`.
    def current_rows_sql
      raise SubclassResponsibilityError
    end

    def journal_table_name = journal_class.table_name

    def journaled_columns
      journal_class.column_names - [journal_class.primary_key, "journal_id"]
    end

    def sink_columns_sql
      ["journal_id", *journaled_columns].join(", ")
    end

    def source_columns_sql
      [id_from_inserted_journal_sql, *journaled_columns.map { "current_rows.#{source_column(it)}" }].join(", ")
    end

    def changed_columns_condition_sql
      journaled_columns
        .map do |column|
          current = "current_rows.#{source_column(column)}"
          journaled = "#{journal_table_name}.#{column}"

          if text_column?(column)
            "(#{normalize_newlines_sql(current)} IS DISTINCT FROM #{normalize_newlines_sql(journaled)})"
          else
            "(#{current} IS DISTINCT FROM #{journaled})"
          end
        end
        .join(" OR ")
    end

    def upsert_sql
      updates = (journaled_columns - [reference_column]).map { "#{it} = EXCLUDED.#{it}" }

      "ON CONFLICT (journal_id, #{reference_column}) DO UPDATE SET #{updates.join(', ')}"
    end

    def source_column(column)
      column == reference_column ? "id" : column
    end

    def text_column?(column)
      journal_class.columns_hash[column].type == :text
    end
  end
end
