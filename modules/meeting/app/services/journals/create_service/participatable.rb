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
  class Participatable < Association
    def associated?
      journable.respond_to?(:participants)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "meeting_participant_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:)
        INSERT INTO
          meeting_participant_journals (
            journal_id,
            user_id,
            invited,
            attended,
            participation_status
          )
        SELECT
          #{id_from_inserted_journal_sql},
          participants.user_id,
          COALESCE(participants.invited, false),
          COALESCE(participants.attended, false),
          participants.participation_status
        FROM (#{current_participants_sql}) participants
        WHERE
          #{only_if_created_sql}
        ON CONFLICT (journal_id, user_id) DO UPDATE SET
          invited = EXCLUDED.invited,
          attended = EXCLUDED.attended,
          participation_status = EXCLUDED.participation_status
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          meeting_participant_journals
        ON
          meeting_participant_journals.journal_id = max_journals.id
        FULL JOIN
          (#{current_participants_sql}) participants
        ON
          participants.user_id = meeting_participant_journals.user_id
        WHERE
          (participants.user_id IS DISTINCT FROM meeting_participant_journals.user_id)
          OR (participants.invited IS DISTINCT FROM meeting_participant_journals.invited)
          OR (participants.attended IS DISTINCT FROM meeting_participant_journals.attended)
          OR (participants.participation_status IS DISTINCT FROM meeting_participant_journals.participation_status)
      SQL
    end

    private

    def current_participants_sql
      <<~SQL.squish
        SELECT DISTINCT ON (meeting_participants.user_id)
          meeting_participants.user_id,
          COALESCE(meeting_participants.invited, false) AS invited,
          COALESCE(meeting_participants.attended, false) AS attended,
          meeting_participants.participation_status
        FROM meeting_participants
        WHERE
          meeting_participants.meeting_id = :journable_id
          AND meeting_participants.user_id IS NOT NULL
        ORDER BY
          meeting_participants.user_id,
          meeting_participants.updated_at DESC,
          meeting_participants.id DESC
      SQL
    end
  end
end
