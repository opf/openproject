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

class AddRecurrenceIdToMeetings < ActiveRecord::Migration[8.0]
  def up
    add_column :meetings, :recurrence_start_time, :datetime, precision: nil

    # Set recurrence start time as the start time as a default
    execute <<~SQL.squish
      UPDATE meetings
      SET recurrence_start_time = meetings.start_time
      WHERE meetings.recurring_meeting_id IS NOT NULL
        AND meetings.template = false
    SQL

    # Back-fill recurrence_start_time: use scheduled_meetings.start_time as a default
    execute <<~SQL.squish
      UPDATE meetings
      SET recurrence_start_time = (
        SELECT sm.start_time FROM scheduled_meetings sm WHERE sm.meeting_id = meetings.id LIMIT 1
      )
      WHERE meetings.recurring_meeting_id IS NOT NULL
        AND meetings.template = false
    SQL

    # Add a partial unique index so two occurrences of the same series cannot share
    # the same canonical recurrence_start_time
    add_index :meetings,
              %i[recurring_meeting_id recurrence_start_time],
              unique: true,
              where: "recurrence_start_time IS NOT NULL AND template = false",
              name: "index_meetings_on_recurring_meeting_and_recurrence_start_time"

    # Create cancelled Meeting stubs for cancelled scheduled_meetings that have no meeting
    # Copy title/duration/location/author/project from the series template
    execute <<~SQL.squish
      INSERT INTO meetings
        (title, author_id, project_id, location, start_time, duration, state,
         recurring_meeting_id, template, recurrence_start_time, lock_version, created_at, updated_at)
      SELECT
        templates.title,
        templates.author_id,
        templates.project_id,
        templates.location,
        sm.start_time,
        templates.duration,
        4,
        sm.recurring_meeting_id,
        false,
        sm.start_time,
        0,
        NOW(),
        NOW()
      FROM scheduled_meetings sm
      JOIN meetings templates
        ON templates.recurring_meeting_id = sm.recurring_meeting_id
        AND templates.template = true
      WHERE sm.cancelled = true
        AND sm.meeting_id IS NULL
    SQL
  end

  def down
    remove_index :meetings, name: "index_meetings_on_recurring_meeting_and_recurrence_start_time"

    # Restore scheduled_meetings for all occurrence meetings (cancelled or not)
    execute <<~SQL.squish
      INSERT INTO scheduled_meetings
        (recurring_meeting_id, meeting_id, start_time, cancelled, created_at, updated_at)
      SELECT
        m.recurring_meeting_id,
        CASE WHEN m.state = 4 THEN NULL ELSE m.id END,
        m.recurrence_start_time,
        (m.state = 4),
        m.created_at,
        m.updated_at
      FROM meetings m
      WHERE m.recurring_meeting_id IS NOT NULL
        AND m.recurrence_start_time IS NOT NULL
        AND m.template = false
    SQL

    # Remove the stub cancelled meetings that were created from scheduled_meetings
    execute <<~SQL.squish
      DELETE FROM meetings
      WHERE state = 4
        AND recurrence_start_time IS NOT NULL
        AND template = false
    SQL

    # Clear recurrence_start_time on remaining meetings
    execute "UPDATE meetings SET recurrence_start_time = NULL"

    remove_column :meetings, :recurrence_start_time
  end
end
