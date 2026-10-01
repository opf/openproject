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

class BackfillMissingRecurrenceStartTime < ActiveRecord::Migration[8.1]
  def up
    # AddRecurrenceIdToMeetings backfilled recurrence_start_time from start_time,
    # but occurrences whose scheduled_meetings link was already missing ended up
    # NULL. Setting those to start_time can collide with the unique index
    # (recurring_meeting_id, recurrence_start_time) when another occurrence in the
    # same series already owns that slot: such rows are duplicate occurrences.
    #
    # We do not delete them. Instead we detach the duplicate from its series
    # (recurring_meeting_id => NULL), turning it into a standalone meeting so no
    # data is lost. The occurrence that keeps the slot is backfilled below.

    # Duplicate of an occurrence that already owns the slot (recurrence_start_time set).
    execute <<~SQL.squish
      UPDATE meetings dup
      SET recurring_meeting_id = NULL,
          recurrence_start_time = NULL,
          updated_at = NOW()
      WHERE dup.recurring_meeting_id IS NOT NULL
        AND dup.template = false
        AND dup.recurrence_start_time IS NULL
        AND EXISTS (
          SELECT 1 FROM meetings holder
          WHERE holder.recurring_meeting_id = dup.recurring_meeting_id
            AND holder.template = false
            AND holder.id <> dup.id
            AND holder.recurrence_start_time = dup.start_time
        )
    SQL

    # Two or more NULL occurrences share the same slot: keep the newest, detach the rest.
    execute <<~SQL.squish
      UPDATE meetings dup
      SET recurring_meeting_id = NULL,
          recurrence_start_time = NULL,
          updated_at = NOW()
      WHERE dup.recurring_meeting_id IS NOT NULL
        AND dup.template = false
        AND dup.recurrence_start_time IS NULL
        AND EXISTS (
          SELECT 1 FROM meetings other
          WHERE other.recurring_meeting_id = dup.recurring_meeting_id
            AND other.template = false
            AND other.recurrence_start_time IS NULL
            AND other.start_time = dup.start_time
            AND other.id > dup.id
        )
    SQL

    # Backfill the occurrences that simply lost their scheduled_meetings link.
    execute <<~SQL.squish
      UPDATE meetings
      SET recurrence_start_time = meetings.start_time
      WHERE meetings.recurring_meeting_id IS NOT NULL
        AND meetings.template = false
        AND meetings.recurrence_start_time IS NULL
    SQL
  end

  def down
    # No-op
  end
end
