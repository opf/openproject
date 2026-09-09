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
  # Journals the version associations of a work package. Only the kinds listed
  # in JOURNALED_KINDS are snapshotted.
  class WorkPackageVersion < Association
    JOURNALED_KINDS = %w[target observed_in].freeze

    def associated?
      journable.respond_to?(:target_versions)
    end

    def cleanup_predecessor(predecessor, notes, cause)
      cleanup_predecessor_for(predecessor,
                              notes,
                              cause,
                              "work_package_version_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:, kinds: JOURNALED_KINDS)
        INSERT INTO
          work_package_version_journals (
            journal_id,
            version_id,
            kind
          )
        SELECT
          #{id_from_inserted_journal_sql},
          work_package_versions.version_id,
          work_package_versions.kind
        FROM work_package_versions
        WHERE
          #{only_if_created_sql}
          AND work_package_versions.work_package_id = :journable_id
          AND work_package_versions.kind IN (:kinds)
      SQL
    end

    # Compares the current (kind, version_id) set with the one stored for the
    # most recent journal. Each side aggregates into a single row (NULL for an
    # empty set), so a plain IS DISTINCT FROM detects additions, removals and
    # replacements across all journaled kinds alike.
    def changes_sql
      sanitize(<<~SQL.squish, journable_id:, kinds: JOURNALED_KINDS)
        SELECT
          :journable_id AS journable_id
        FROM
          (
            SELECT ARRAY_AGG((kind, version_id) ORDER BY kind, version_id) AS versions
            FROM work_package_versions
            WHERE work_package_versions.work_package_id = :journable_id
              AND work_package_versions.kind IN (:kinds)
          ) current_versions
        CROSS JOIN
          (
            SELECT ARRAY_AGG((kind, version_id) ORDER BY kind, version_id) AS versions
            FROM work_package_version_journals
            WHERE journal_id IN (SELECT id FROM max_journals)
              AND kind IN (:kinds)
          ) journal_versions
        WHERE
          current_versions.versions IS DISTINCT FROM journal_versions.versions
      SQL
    end
  end
end
