#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Scope to fetch all fields necessary to populated AggregatedJournal collections.
# See the AggregatedJournal model class for a description.
module Journal::Scopes
  class AggregatedJournal
    class << self
      def fetch(journable: nil, sql: nil, until_version: nil)
        journals_preselection = raw_journals_subselect(journable, sql, until_version)

        # We wrap the sql with a subselect so that outside of this class,
        # The fields native to journals (e.g. id, version) can be referenced, without
        # having to also use a CASE/COALESCE statement.
        Journal
          .from(select_sql(journals_preselection))
      end

      private

      # The sql used to query the database for the aggregated journals.
      # The query makes use of 4 parts (which are selected from/joined):
      #  * The minimum journal version that starts an aggregation group.
      #  * The maximum journal version that ends an aggregation group.
      #  * Journals with notes that are within the bounds of minimum version/maximum version.
      #  * Journals with notes that are within the bounds of the before mentioned journal notes and the maximum journal version.
      #
      # The maximum version are those journals, whose successor:
      #  * Where created by a different user
      #  * Where created after the configured aggregation period had expired (always relative to the journal under consideration).
      #
      # The minimum version then is the maximum version of the group before - 1.
      #
      # e.g. a group of 10 sequential journals might break into the following groups
      #
      #   Version 10 (User A, 6 minutes after 9)
      #   Version 9 (User A, 2 minutes after 8)
      #   Version 8 (User A, 4 minutes after 7)
      #   Version 7 (User A, 1 minute after 6)
      #   Version 6 (User A, 3 minutes after 5)
      #   Version 5 (User A, 1 minute after 4)
      #   Version 4 (User B, 1 minute after 3)
      #   Version 3 (User B, 4 minutes after 2)
      #   Version 2 (User A, 1 minute after 1)
      #   Version 1 (User A)
      #
      # would have the following maximum journals if the aggregation period where 5 minutes:
      #
      #   Version 10 (User A, 6 minutes after 9)
      #   Version 9 (User A, 2 minutes after 8)
      #   Version 4 (User B, 1 minute after 3)
      #   Version 2 (User A, 1 minute after 1)
      #
      # The last journal (one without a successor) of a journable will obviously also always be a maximum journal.
      #
      # If the aggregation period where to be expanded to 7 minutes, the maximum journals would be slightly different:
      #
      #   Version 10 (User A, 6 minutes after 9)
      #   Version 4 (User B, 1 minute after 3)
      #   Version 2 (User A, 1 minute after 1)
      #
      # As we do not store the aggregated journals, and rather calculate them on reading, the aggregated journals might be tuned
      # by a user.
      #
      # The minimum version in the example with the 5 minute aggregation period would then be calculated from the maximum version:
      #
      #   Version 10
      #   Version 5
      #   Version 3
      #   Version 1
      #
      # The first version will always be included.
      #
      # Without a journal with notes (the user commented on the journable) in between, the maximum journal is returned
      # as the representation of every aggregation group. This is possible as the journals (together with their data and their
      # customizable_journals/attachable_journals) represent the complete state of the journable at the given time.
      #
      # e.g. a group of 5 sequential journals without notes, belonging to the same user and created within the configured
      # time difference between one journal and its succcessor
      #
      #   Version 9
      #   Version 8
      #   Version 7
      #   Version 6
      #   Version 5
      #
      # would only return the last journal, Version 9.
      #
      # In case the group has one journal with notes in it, the last journal is also returned. But as we also want the note
      # to be returned, we return the note as if it would belong to the maximum journal version. This explicitly means
      # that all journals of the same group that are after the notes journal are also returned.
      #
      # e.g. a group of 5 sequential journals with only one note, belonging to the same user and created within the configured
      # time difference between one journal and its succcessor
      #
      #   Version 9
      #   Version 8
      #   Version 7
      #   Version 6 (note)
      #   Version 5
      #
      # would only return the last journal, Version 9, but would also return the note and the id of the journal the note
      # belongs to natively.
      #
      # But as we do not want to aggregate notes, the behaviour above can no longer work if there is more than one note in the
      # same group. In such a case, a group is cut into subsets. The journals returned will then only contain all the changes
      # up until a journal with notes. The only exception to this is the last journal note which might also contain changes
      # after it up to and including the maximum journal version of the group.

      # e.g. a group of 5 sequential journals with only one note, belonging to the same user and created within the configured
      # time difference between one journal and its succcessor
      #
      #   Version 9
      #   Version 8 (note)
      #   Version 7
      #   Version 6 (note)
      #   Version 5
      #
      # would return the last journal, Version 9, but with the note of Version 8 and also a reference in the form of
      # note_id pointing to Version 8. It would also return Version 6, with its note and a reference in the form of note_id
      # this time pointing to the native journal, Version 6.
      #
      # The journals that are considered for aggregation can also be reduced by providing a subselect. Doing so, one
      # can e.g. consider only the journals created after a certain time.
      def select_sql(journals_preselection)
        <<~SQL
          (#{Journal
               .from(start_group_journals_select(journals_preselection))
               .joins(end_group_journals_join(journals_preselection))
               .joins(notes_in_group_join(journals_preselection))
               .joins(additional_notes_in_group_join(journals_preselection))
               .select(projection_list).to_sql}) journals
        SQL
      end

      def user_or_time_group_breaking_journals_subselect(journals_preselection)
        <<~SQL
          SELECT
            predecessor.*,
            row_number() OVER (ORDER BY predecessor.journable_type, predecessor.journable_id, predecessor.version ASC) #{group_number_alias}
          FROM #{journals_preselection} predecessor
            LEFT OUTER JOIN #{journals_preselection} successor
            ON predecessor.version + 1 = successor.version
            AND predecessor.journable_type = successor.journable_type
            AND predecessor.journable_id = successor.journable_id
            WHERE (predecessor.user_id != successor.user_id
            OR #{beyond_aggregation_time_condition})
            OR successor.id IS NULL
        SQL
      end

      def notes_journals_subselect(journals_preselection)
        <<~SQL
          (SELECT
            notes_journals.*
          FROM #{journals_preselection} notes_journals
            WHERE notes_journals.notes != '' AND notes_journals.notes IS NOT NULL)
        SQL
      end

      def start_group_journals_select(journals_preselection)
        "(#{user_or_time_group_breaking_journals_subselect(journals_preselection)}) #{start_group_journals_alias}"
      end

      def end_group_journals_join(journals_preselection)
        group_journals_join_condition = <<~SQL
          #{start_group_journals_alias}.#{group_number_alias} = #{end_group_journals_alias}.#{group_number_alias} - 1
          AND #{start_group_journals_alias}.journable_type = #{end_group_journals_alias}.journable_type
          AND #{start_group_journals_alias}.journable_id = #{end_group_journals_alias}.journable_id
        SQL

        end_group_journals = <<~SQL
          RIGHT OUTER JOIN
            (#{user_or_time_group_breaking_journals_subselect(journals_preselection)}) #{end_group_journals_alias}
            ON #{group_journals_join_condition}
        SQL

        Arel.sql(end_group_journals)
      end

      def notes_in_group_join(journals_preselection)
        # As we right join on the minimum journal version, the minimum might be empty. We thus have to coalesce in such
        # case as <= will not interpret NULL as 0.
        # This also works if we do not fetch the whole set of journals starting from the first journal but rather
        # start somewhere within the set. This might take place e.g. when fetching only the journals that are
        # created after a certain point in time which is done when displaying of the last month in the activity module.
        breaking_journals_notes_join_condition = <<~SQL
          COALESCE(#{start_group_journals_alias}.version, 0) + 1 <= #{notes_in_group_alias}.version
          AND #{end_group_journals_alias}.version >= #{notes_in_group_alias}.version
          AND #{end_group_journals_alias}.journable_type = #{notes_in_group_alias}.journable_type
          AND #{end_group_journals_alias}.journable_id = #{notes_in_group_alias}.journable_id
        SQL

        breaking_journals_notes = <<~SQL
          LEFT OUTER JOIN
            #{notes_journals_subselect(journals_preselection)} #{notes_in_group_alias}
            ON #{breaking_journals_notes_join_condition}
        SQL

        Arel.sql(breaking_journals_notes)
      end

      def additional_notes_in_group_join(journals_preselection)
        successor_journals_notes_join_condition = <<~SQL
          #{notes_in_group_alias}.version < successor_notes.version
          AND #{end_group_journals_alias}.version >= successor_notes.version
          AND #{end_group_journals_alias}.journable_type = successor_notes.journable_type
          AND #{end_group_journals_alias}.journable_id = successor_notes.journable_id
        SQL

        successor_journals_notes = <<~SQL
          LEFT OUTER JOIN
            #{notes_journals_subselect(journals_preselection)} successor_notes
            ON #{successor_journals_notes_join_condition}
        SQL

        Arel.sql(successor_journals_notes)
      end

      def projection_list
        projections = <<~SQL
          #{end_group_journals_alias}.journable_type,
          #{end_group_journals_alias}.journable_id,
          #{end_group_journals_alias}.user_id,
          #{end_group_journals_alias}.activity_type,
          #{notes_projection} notes,
          #{notes_id_projection} notes_id,
          #{notes_in_group_alias}.version notes_version,
          #{version_projection} AS version,
          #{created_at_projection} created_at,
          #{id_projection} id
        SQL

        Arel.sql(projections)
      end

      def id_projection
        <<~SQL
          CASE
            WHEN successor_notes.version IS NOT NULL THEN #{notes_in_group_alias}.id
            ELSE #{end_group_journals_alias}.id END
        SQL
      end

      def version_projection
        <<~SQL
          CASE
          WHEN successor_notes.version IS NOT NULL THEN #{notes_in_group_alias}.version
          ELSE #{end_group_journals_alias}.version END
        SQL
      end

      def created_at_projection
        <<~SQL
          CASE
            WHEN successor_notes.version IS NOT NULL THEN #{notes_in_group_alias}.created_at
            ELSE #{end_group_journals_alias}.created_at END
        SQL
      end

      def notes_id_projection
        <<~SQL
          COALESCE(#{notes_in_group_alias}.id, #{end_group_journals_alias}.id)
        SQL
      end

      def notes_projection
        <<~SQL
          COALESCE(#{notes_in_group_alias}.notes, '')
        SQL
      end

      def raw_journals_subselect(journable, sql, until_version)
        if sql
          raise 'until_version used together with sql' if until_version

          "(#{sql})"
        elsif journable
          limit = until_version ? "AND journals.version <= #{until_version}" : ''

          <<~SQL
            (
              SELECT * from journals
              WHERE journals.journable_id = #{journable.id}
              AND journals.journable_type = '#{journable.class.name}'
              #{limit}
            )
          SQL
        else
          where = until_version ? "WHERE journals.version <= #{until_version}" : ''

          <<~SQL
            (SELECT * from journals #{where})
          SQL
        end
      end

      # Returns a SQL condition that will determine whether two entries are too far apart (temporal)
      # to be considered for aggregation. This takes the current instance settings for temporal
      # proximity into account.
      def beyond_aggregation_time_condition
        aggregation_time_seconds = Setting.journal_aggregation_time_minutes.to_i.minutes
        if aggregation_time_seconds == 0
          # if aggregation is disabled, we consider everything to be beyond aggregation time
          # even if creation dates are exactly equal
          return '(true = true)'
        end

        difference = "(successor.created_at - predecessor.created_at)"
        threshold = "interval '#{aggregation_time_seconds} second'"

        "(#{difference} > #{threshold})"
      end

      def start_group_journals_alias
        "start_groups_journals"
      end

      def end_group_journals_alias
        "end_groups_journals"
      end

      def group_number_alias
        "group_number"
      end

      def notes_in_group_alias
        "notes_in_group_journals"
      end
    end
  end
end
