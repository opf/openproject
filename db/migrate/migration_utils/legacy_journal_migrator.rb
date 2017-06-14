#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'db_worker'
require_relative 'legacy_table_checker'
require_relative 'legacy_yamler'

module Migration
  class IncompleteJournalsError < ::StandardError
  end

  class AmbiguousJournalsError < ::StandardError
  end

  class LegacyJournalMigrator
    include DbWorker
    include LegacyTableChecker
    include LegacyYamler

    attr_accessor :table_name,
                  :type,
                  :journable_class

    def initialize(type, table_name, &block)
      self.table_name = table_name
      self.type = type

      instance_eval &block if block_given?

      if table_name.nil? || type.nil?
        raise ArgumentError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
          table_name and type have to be provided. Either as parameters
          or set within the block.
        MESSAGE
      end

      self.journable_class ||= self.type.gsub(/Journal\z/, '')
    end

    def run
      unless preconditions_met?
        puts <<-MESSAGE
          There is no legacy_journals table from which to derive the new
          journals. Doing nothing ...
        MESSAGE
        return
      end

      legacy_journals = fetch_legacy_journals
      total_count = legacy_journals.count

      if total_count > 1
        progress_bar = ProgressBar.create(format: '%a <%B> %P%% %e',
                                          total: total_count,
                                          throttle_rate: 1,
                                          smoothing: 0.5)
        progress_bar.log "Migrating #{total_count} legacy journals."

        legacy_journals.each_with_index do |legacy_journal, _count|
          migrate(legacy_journal)
          progress_bar.increment
        end
      end
    end

    def remove_journals_derived_from_legacy_journals(*table_names)
      table_names << table_name

      if legacy_table_exists?

        table_names.each do |table_name|
          db_delete <<-SQL
          DELETE
          FROM #{quoted_table_name(table_name)}
          WHERE journal_id in (SELECT id
                               FROM #{quoted_legacy_journals_table_name}
                               WHERE type=#{quote_value(type)})
          SQL
        end

        db_delete <<-SQL
        DELETE
        FROM journals
        WHERE id in (SELECT id
                     FROM #{quoted_legacy_journals_table_name}
                     WHERE type=#{quote_value(type)})
        SQL
      else
        puts 'No legacy table exists. Doing nothing'
      end
    end

    protected

    def migrate(legacy_journal)
      journal = set_journal(legacy_journal)
      journal_id = journal['id']

      set_journal_data(journal_id, legacy_journal)
    end

    def combine_journal(journaled_id, legacy_journal)
      # compute the combined journal from current and all previous changesets.
      combined_journal = legacy_journal['changed_data']
      if previous.journaled_id == journaled_id
        combined_journal = previous.journal.merge(combined_journal)
      end

      # remember the combined journal as the previous one for the next iteration.
      previous.set(combined_journal, journaled_id)

      combined_journal
    end

    def previous
      @previous ||= PreviousState.new({}, 0)
    end

    # here to be overwritten by instances
    def migrate_key_value_pairs!(_to_insert, _legacy_journal, _journal_id) end

    # fetches specific journal data row. might be empty.
    def fetch_existing_data_journal(journal_id)
      db_select_all <<-SQL
        SELECT *
        FROM #{journal_table_name} AS d
        WHERE d.journal_id = #{quote_value(journal_id)};
      SQL
    end

    # gets a journal row, and makes sure it has a valid id in the database.
    # if the journal does not exist, it creates it
    def set_journal(legacy_journal)
      journal = fetch_journal(legacy_journal)

      if journal.size > 1

        raise AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
          It appears there are ambiguous journals. Please make sure
          journals are consistent and that the unique constraint on id,
          type and version is met.
        MESSAGE

      elsif journal.size == 0

        journal = create_journal(legacy_journal)

      end

      journal.first
    end

    # fetches specific journal row. might be empty.
    def fetch_journal(legacy_journal)
      id = legacy_journal['journaled_id']
      version = legacy_journal['version']

      db_select_all <<-SQL
        SELECT *
        FROM #{quoted_journals_table_name} AS j
        WHERE j.journable_id = #{quote_value(id)}
          AND j.journable_type = #{quote_value(journable_class)}
          AND j.version = #{quote_value(version)};
      SQL
    end

    # creates a valid journal.
    # But might be not what is desired as an end result, yet.  It is e.g.
    # created with created_at set to now. This will need to be set to an actual
    # date
    def create_journal(legacy_journal)
      db_execute <<-SQL
        INSERT INTO #{quoted_journals_table_name} (
          id,
          journable_id,
          version,
          user_id,
          notes,
          activity_type,
          created_at,
          journable_type
        )
        VALUES (
          #{quote_value(legacy_journal['id'])},
          #{quote_value(legacy_journal['journaled_id'])},
          #{quote_value(legacy_journal['version'])},
          #{quote_value(legacy_journal['user_id'])},
          #{quote_value(legacy_journal['notes'])},
          #{quote_value(legacy_journal['activity_type'])},
          #{quote_value(legacy_journal['created_at'])},
          #{quote_value(journable_class)}
        );
      SQL

      fetch_journal(legacy_journal)
    end

    def set_journal_data(journal_id, legacy_journal)
      deserialize_journal(legacy_journal)
      journaled_id = legacy_journal['journaled_id']

      combined_journal = combine_journal(journaled_id, legacy_journal)
      migrate_key_value_pairs!(combined_journal, legacy_journal, journal_id)

      to_insert = insertable_data_journal(combined_journal)

      existing_data_journal = fetch_existing_data_journal(journal_id)

      if existing_data_journal.size > 1

        raise AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
          It appears there are ambiguous journal data. Please make sure
          journal data are consistent and that the unique constraint on
          journal_id is met.
        MESSAGE

      elsif existing_data_journal.size == 0

        existing_data_journal = create_data_journal(journal_id, to_insert)

      end

      existing_data_journal = existing_data_journal.first

      update_data_journal(existing_data_journal['id'], to_insert)
    end

    def create_data_journal(journal_id, to_insert)
      keys = to_insert.keys
      values = to_insert.values

      db_execute <<-SQL
        INSERT INTO #{journal_table_name} (journal_id#{', ' + keys.join(', ') unless keys.empty?})
        VALUES (#{quote_value(journal_id)}#{', ' + values.map { |d| quote_value(d) }.join(', ') unless values.empty?});
      SQL

      fetch_existing_data_journal(journal_id)
    end

    def update_data_journal(id, to_insert)
      db_execute <<-SQL unless to_insert.empty?
        UPDATE #{journal_table_name}
           SET #{(to_insert.each.map { |key, value| "#{key} = #{quote_value(value)}" }).join(', ')}
         WHERE id = #{id};
      SQL
    end

    def deserialize_changed_data(journal)
      changed_data = journal['changed_data']
      return Hash.new if changed_data.nil?
      load_with_syck(changed_data)
    end

    def deserialize_journal(journal)
      integerize_ids(journal)
      journal['changed_data'] = deserialize_changed_data(journal)
    end

    def insertable_data_journal(journal)
      journal.inject({}) do |mem, (key, value)|
        current_key = map_key(key)

        if column_names.include?(current_key)
          # The old journal's values attribute was structured like
          # [old_value, new_value]
          # We only need the new_value
          mem[current_key] = value.last
        end

        mem
      end
    end

    def map_key(key)
      case key
      when 'issue_id'
        'work_package_id'
      when 'tracker_id'
        'type_id'
      when 'end_date'
        'due_date'
      when 'name'
        'subject'
      else
        key
      end
    end

    def integerize_ids(journal)
      # turn id fields into integers.
      ['id', 'journaled_id', 'user_id', 'version'].each do |f|
        journal[f] = journal[f].to_i
      end
    end

    # fetches legacy journals. might me empty.
    def fetch_legacy_journals
      db_select_all <<-SQL
        SELECT *
        FROM #{quoted_legacy_journals_table_name} AS j
        WHERE (j.type = #{quote_value(type)})
        ORDER BY j.journaled_id, j.type, j.version;
      SQL
    end

    def preconditions_met?
      legacy_table_exists? && check_legacy_journal_completeness
    end

    def check_legacy_journal_completeness
      # SQL finds all those journals whose has more or less predecessors than
      # it's version would require. Ignores the first journal.
      # e.g. a journal with version 5 would have to have 5 predecessors
      invalid_journals = db_select_all <<-SQL
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
          AND (a.type = #{quote_value(type)})
          GROUP BY
            a.id,
            a.journaled_id,
            a.type,
            a.version
        ) AS tmp
        WHERE
          NOT (tmp.version = tmp.count);
      SQL

      # @TODO don't ignore invalid journals
      unless true || invalid_journals.empty?
        raise IncompleteJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
          It appears there are incomplete journals. Please make sure
          journals are consistent and that for every journal, there is an
          initial journal containing all attribute values at the time of
          creation. The offending journal ids are: #{invalid_journals}
        MESSAGE
      end

      true
    end

    def journal_table_name
      @journal_table_name ||= quoted_table_name(table_name)
    end

    def quoted_legacy_journals_table_name
      @quoted_legacy_journals_table_name ||= quoted_table_name 'legacy_journals'
    end

    def quoted_journals_table_name
      @quoted_journals_table_name ||= quoted_table_name 'journals'
    end

    def column_names
      @column_names ||= db_columns(table_name).map(&:name)
    end
  end

  class PreviousState < Struct.new(:journal, :journaled_id)
    def set(journal, journaled_id)
      self.journal = journal
      self.journaled_id = journaled_id
    end
  end
end
