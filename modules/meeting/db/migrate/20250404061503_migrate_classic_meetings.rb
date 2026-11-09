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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# rubocop:disable Rails/SquishedSQLHeredocs
# frozen_string_literal: true

class MigrateClassicMeetings < ActiveRecord::Migration[8.0]
  def up
    # Create default sections for meetings that don't have one
    execute <<~SQL
      INSERT INTO meeting_sections (meeting_id, title, position, created_at, updated_at)
      SELECT m.id, '', 1, NOW(), NOW()
      FROM meetings m
      LEFT JOIN meeting_sections ms ON ms.meeting_id = m.id
      WHERE ms.id IS NULL;
    SQL

    # Migrate MeetingAgenda content to MeetingAgendaItem
    execute <<~SQL.squish
      INSERT INTO meeting_agenda_items (
        meeting_id,
        meeting_section_id,
        author_id,
        presenter_id,
        title,
        notes,
        position,
        created_at,
        updated_at
      )
      SELECT
        mc.meeting_id,
        ms.id,
        mc.author_id,
        mc.author_id,
        '#{I18n.t(:label_meeting_agenda)}',
        mc.text,
        1,
        mc.created_at,
        mc.updated_at
      FROM meeting_contents mc
      INNER JOIN meetings m ON m.id = mc.meeting_id
      INNER JOIN meeting_sections ms ON ms.meeting_id = m.id
      WHERE mc.type = 'MeetingAgenda';
    SQL

    # Migrate MeetingMinutes to MeetingOutcome
    execute <<~SQL.squish
      INSERT INTO meeting_outcomes (
        meeting_agenda_item_id,
        author_id,
        notes,
        created_at,
        updated_at
      )
      SELECT
        mai.id,
        mc.author_id,
        mc.text,
        mc.created_at,
        mc.updated_at
      FROM meeting_contents mc
      INNER JOIN meetings m ON m.id = mc.meeting_id
      INNER JOIN meeting_sections ms ON ms.meeting_id = m.id
      INNER JOIN meeting_agenda_items mai ON mai.meeting_id = m.id
      WHERE mc.type = 'MeetingMinutes';
    SQL

    # Close classic meetings that are in the past
    execute <<~SQL.squish
      UPDATE meetings
      SET state = 5
      WHERE type = 'Meeting'
      AND start_time < CURRENT_TIMESTAMP
    SQL

    # Remove STI column
    remove_column :meetings, :type
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Rails/SquishedSQLHeredocs
