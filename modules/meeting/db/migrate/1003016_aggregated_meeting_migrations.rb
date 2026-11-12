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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s
require Rails.root.join("db/migrate/tables/base").to_s
Dir[File.join(__dir__, "tables/*.rb")].each { |file| require file }

class AggregatedMeetingMigrations < SquashedMigration
  squashed_migrations *%w[
    1003015_aggregated_meeting_migrations
    20250318123314_add_backlog_to_meeting_sections
    20240426073948_create_recurring_meetings
    20241122143600_add_interval_to_recurring_meeting
    20241128190428_create_scheduled_meetings
    20250211185841_create_meeting_outcomes
    20250227140619_change_unique_constraint_on_scheduled_meetings
    20250304082924_add_time_zone_to_recurring_meetings
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
