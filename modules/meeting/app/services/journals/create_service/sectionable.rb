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
  class Sectionable < Association
    include JournalTableColumns

    def associated?
      journable.respond_to?(:sections)
    end

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
          #{source_columns_sql('sections')}
        FROM (#{current_sections_sql}) sections
        WHERE
          #{only_if_created_sql}
        #{upsert_sql}
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          #{journal_table_name}
        ON
          #{journal_table_name}.journal_id = max_journals.id
        FULL JOIN
          (#{current_sections_sql}) sections
        ON
          sections.id = #{journal_table_name}.#{reference_column}
        WHERE
          #{changed_columns_condition_sql('sections')}
      SQL
    end

    private

    def journal_class = Journal::MeetingSectionJournal

    def reference_column = "section_id"

    def current_sections_sql
      "SELECT * FROM meeting_sections WHERE meeting_sections.meeting_id = :journable_id"
    end
  end
end
