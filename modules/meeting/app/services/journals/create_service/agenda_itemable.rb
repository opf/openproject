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
  class AgendaItemable < Association
    def associated?
      journable.respond_to?(:agenda_items)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "meeting_agenda_item_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:)
        INSERT INTO
          meeting_agenda_item_journals (
            journal_id,
            agenda_item_id,
            author_id,
            title,
            notes,
            position,
            duration_in_minutes,
            work_package_id,
            item_type
          )
        SELECT
          #{id_from_inserted_journal_sql},
          agenda_items.id,
          agenda_items.author_id,
          agenda_items.title,
          agenda_items.notes,
          agenda_items.position,
          agenda_items.duration_in_minutes,
          agenda_items.work_package_id,
          agenda_items.item_type
        FROM meeting_agenda_items agenda_items
        WHERE
          #{only_if_created_sql}
          AND agenda_items.meeting_id = :journable_id
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          meeting_agenda_item_journals
        ON
          meeting_agenda_item_journals.journal_id = max_journals.id
        FULL JOIN
          (SELECT *
           FROM meeting_agenda_items
           WHERE meeting_agenda_items.meeting_id = :journable_id) agenda_items
        ON
          agenda_items.id = meeting_agenda_item_journals.agenda_item_id
        WHERE
          (agenda_items.id IS DISTINCT FROM meeting_agenda_item_journals.agenda_item_id)
          OR (agenda_items.title IS DISTINCT FROM meeting_agenda_item_journals.title)
          OR (#{normalize_newlines_sql('agenda_items.notes')} IS DISTINCT FROM
              #{normalize_newlines_sql('meeting_agenda_item_journals.notes')})
          OR (agenda_items.position IS DISTINCT FROM meeting_agenda_item_journals.position)
          OR (agenda_items.duration_in_minutes IS DISTINCT FROM meeting_agenda_item_journals.duration_in_minutes)
          OR (agenda_items.work_package_id IS DISTINCT FROM meeting_agenda_item_journals.work_package_id)
          OR (agenda_items.item_type IS DISTINCT FROM meeting_agenda_item_journals.item_type)
      SQL
    end
  end
end
