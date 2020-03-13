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

module Journal::Scopes
  class AggregatedJournal
    class << self
      def fetch(journable: nil, sql: nil, until_version: nil)
        journals_preselection = raw_journals_subselect(journable, sql, until_version)

        Journal
          .from(select_sql(journals_preselection))
      end

      private

      def select_sql(journals_preselection)
        # Using the roughly aggregated groups from :sql_rough_group we need to merge journals
        # where an entry with empty notes follows an entry containing notes, so that the notes
        # from the main entry are taken, while the remaining information is taken from the
        # more recent entry. We therefore join the rough groups with itself
        # _wherever a merge would be valid_.
        # Since the results are already pre-merged, this can only happen if Our first entry (master)
        # had a comment and its successor (addition) had no comment, but can be merged.
        # This alone would, however, leave the addition in the result set, leaving a "no change"
        # journal entry back. By an additional self-join towards the predecessor, we can make sure
        # that our own row (master) would not already have been merged by its predecessor. If it is
        # (that means if we can find a valid predecessor), we drop our current row, because it will
        # already be present (in a merged form) in the row of our predecessor.
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
