#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/legacy_journal_migrator'
require_relative 'migration_utils/journal_migrator_concerns'

class AwesomeLegacyJournals < ActiveRecord::Migration


  class UnsupportedWikiContentJournalCompressionError < ::StandardError
  end

  class WikiContentJournalVersionError < ::StandardError
  end

  class AmbiguousJournalsError < ::StandardError
  end

  class AmbiguousAttachableJournalError < AmbiguousJournalsError
  end

  class InvalidAttachableJournalError < ::StandardError
  end

  class AmbiguousCustomizableJournalError < AmbiguousJournalsError
  end

  class IncompleteJournalsError < ::StandardError
  end


  def up
    check_assumptions

    legacy_journals = fetch_legacy_journals

    say "Migrating #{legacy_journals.count} legacy journals."

    legacy_journals.each_with_index do |legacy_journal, count|

      type = legacy_journal["type"]

      migrator = get_migrator(type)

      if migrator.nil?
        ignored[type] += 1

        next
      end

      migrator.migrate(legacy_journal)

      if count > 0 && (count % 1000 == 0)
        say "#{count} journals migrated"
      end
    end

    ignored.each do |type, amount|
      say "#{type} was ignored #{amount} times"
    end
  end

  def down
  end

  private

  def ignored
    @ignored ||= Hash.new do |k, v|
      0
    end
  end

  def get_migrator(type)
    @migrators ||= begin

      {
        "AttachmentJournal" => attachment_migrator,
        "ChangesetJournal" => changesets_migrator,
        "NewsJournal" => news_migrator,
        "MessageJournal" => message_migrator,
        "WorkPackageJournal" => work_package_migrator,
        "IssueJournal" => work_package_migrator,
        "Timelines_PlanningElementJournal" => work_package_migrator,
        "TimeEntryJournal" => time_entry_migrator,
        "WikiContentJournal" => wiki_content_migrator
      }
    end

    @migrators[type]
  end

  def attachment_migrator
    Migration::LegacyJournalMigrator.new("AttachmentJournal", "attachment_journals") do

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        rewrite_issue_container_to_work_package(to_insert)

      end

      def rewrite_issue_container_to_work_package(to_insert)
        if to_insert['container_type'].last == 'Issue'

          to_insert['container_type'][-1] = 'WorkPackage'

        end
      end
    end
  end

  def changesets_migrator
    Migration::LegacyJournalMigrator.new("ChangesetJournal", "changeset_journals")
  end

  def news_migrator
    Migration::LegacyJournalMigrator.new("NewsJournal", "news_journals")
  end

  def message_migrator
    Migration::LegacyJournalMigrator.new("MessageJournal", "message_journals") do
      extend Migration::JournalMigratorConcerns::Attachable

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        migrate_attachments(to_insert, legacy_journal, journal_id)

      end
    end
  end

  def work_package_migrator
    Migration::LegacyJournalMigrator.new "WorkPackageJournal", "work_package_journals" do
      extend Migration::JournalMigratorConcerns::Attachable
      extend Migration::JournalMigratorConcerns::Customizable

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        migrate_attachments(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)

      end
    end
  end

  def planning_element_migrator
    Migration::LegacyJournalMigrator.new "Timelines_PlanningElementJournal", "work_package_journals" do
      extend Migration::JournalMigratorConcern::Attachable
      extend Migration::JournalMigratorConcern::Customizable

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        migrate_attachments(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)

      end

      private

      def new_journaled_id_for_old(old_journaled_id)
        # We should be able to keep that in memory
        @new_journaled_ids ||= begin
          old_new = select_all <<-SQL
            SELECT journaled_id AS old_id, new_id
            FROM legacy_journals
            LEFT JOIN legacy_planning_elements
            ON legacy_journals.journaled_id = legacy_planning_elements.id
            WHERE type = 'Timelines_PlanningElementJournal'
          SQL

          old_new.inject({}) do |mem, entry|
            mem[entry['old_id']] = entry['new_id']
            mem
          end
        end

        @new_journaled_ids[old_journaled_id]
      end
    end
  end

  def time_entry_migrator
    Migration::LegacyJournalMigrator.new("TimeEntryJournal", "time_entry_journals") do
      extend Migration::JournalMigratorConcerns::Customizable

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        migrate_custom_values(to_insert, legacy_journal, journal_id)

      end
    end
  end

  def wiki_content_migrator

    Migration::LegacyJournalMigrator.new("WikiContentJournal", "wiki_content_journals") do

      def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id)

        # remove once lock_version is no longer a column in the wiki_content_journales table
        if !to_insert.has_key?("lock_version")

          if !legacy_journal.has_key?("version")
            raise WikiContentJournalVersionError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
              There is a wiki content without a version.
              The DB requires a version to be set
              #{legacy_journal},
              #{to_insert}
            MESSAGE

          end

          # as the old journals used the format [old_value, new_value] we have to fake it here
          to_insert["lock_version"] = [nil,legacy_journal["version"]]
        end

        if to_insert.has_key?("data")

          # Why is that checked but than the compression is not used in any way to read the data
          if !to_insert.has_key?("compression")

            raise UnsupportedWikiContentJournalCompressionError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
              There is a WikiContent journal that contains data in an
              unsupported compression: #{compression}
            MESSAGE

          end

          # as the old journals used the format [old_value, new_value] we have to fake it here
          to_insert["text"] = [nil, to_insert.delete("data")]
        end
      end

    end
  end

  # fetches legacy journals. might me empty.
  def fetch_legacy_journals

    attachments_and_changesets = ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_legacy_journals_table_name} AS j
      WHERE (j.activity_type = #{quote_value("attachments")})
        OR (j.activity_type = #{quote_value("custom_fields")})
      ORDER BY j.journaled_id, j.type, j.version;
    SQL

    remainder = ActiveRecord::Base.connection.select_all <<-SQL
      SELECT *
      FROM #{quoted_legacy_journals_table_name} AS j
      WHERE NOT ((j.activity_type = #{quote_value("attachments")})
        OR (j.activity_type = #{quote_value("custom_fields")}))
      ORDER BY j.journaled_id, j.type, j.version;
    SQL

    attachments_and_changesets + remainder
  end

  def quoted_legacy_journals_table_name
    @quoted_legacy_journals_table_name ||= quote_table_name 'legacy_journals'
  end

  def check_assumptions

    # SQL finds all those journals whose has more or less predecessors than
    # it's version would require. Ignores the first journal.
    # e.g. a journal with version 5 would have to have 5 predecessors
    invalid_journals = ActiveRecord::Base.connection.select_values <<-SQL
      SELECT DISTINCT tmp.id
      FROM (
        SELECT
          a.id AS id,
          a.journaled_id,
          a.type,
          a.version AS version,
          count(b.id) AS count
        FROM
          #{quoted_legacy_journals_table_name} AS a
        LEFT JOIN
          #{quoted_legacy_journals_table_name} AS b
          ON a.version >= b.version
            AND a.journaled_id = b.journaled_id
            AND a.type = b.type
        WHERE a.version > 1
        GROUP BY
          a.id,
          a.journaled_id,
          a.type,
          a.version
      ) AS tmp
      WHERE
        NOT (tmp.version = tmp.count);
    SQL

    unless invalid_journals.empty?

      raise IncompleteJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        It appears there are incomplete journals. Please make sure
        journals are consistent and that for every journal, there is an
        initial journal containing all attribute values at the time of
        creation. The offending journal ids are: #{invalid_journals}
      MESSAGE
    end
  end

  include ::Migration::DbWorker
end
