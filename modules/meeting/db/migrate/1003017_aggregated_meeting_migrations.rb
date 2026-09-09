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

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
require Rails.root.join("db/migrate/tables/base").to_s
Dir[File.join(__dir__, "tables/*.rb")].each { |file| require file }

class AggregatedMeetingMigrations < SquashedMigration
  squashed_migrations *%w[
    1003016_aggregated_meeting_migrations
    20250404060850_add_author_to_outcome
    20250404061503_migrate_classic_meetings
    20250428114958_cleanup_meeting_permissions
    20250624155721_rename_create_minutes_to_manage_outcomes
    20250703143214_add_uid_to_meetings
    20250804083253_remove_times_for_meeting_agenda_items
    20250808062421_fix_missing_meetings_attachments
    20250416141059_add_backlogs_to_one_time_meetings
    20250709103506_add_notify_status_to_meetings
  ].freeze

  tables Tables::MeetingContents,
         Tables::MeetingParticipants,
         Tables::Meetings,
         Tables::MeetingJournals,
         Tables::MeetingContentJournals,
         Tables::MeetingSections,
         Tables::MeetingAgendaItems,
         Tables::MeetingAgendaItemJournals,
         Tables::RecurringMeetings,
         Tables::ScheduledMeetings,
         Tables::MeetingOutcomes

  modifications do
    # There's no easy way to express deferrable unique constraints in Rails migrations
    execute <<~SQL.squish
      ALTER TABLE scheduled_meetings
      ADD CONSTRAINT unique_recurring_meeting_start_time
      UNIQUE (recurring_meeting_id, start_time) DEFERRABLE INITIALLY DEFERRED;
    SQL
  end
end
