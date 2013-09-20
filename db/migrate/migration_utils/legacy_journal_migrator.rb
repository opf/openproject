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

require_relative 'db_worker'

module Migration
  class AmbiguousJournalsError < ::StandardError
  end

  class LegacyJournalMigrator
    include DbWorker

    attr_accessor :table_name,
                  :type,
                  :journable_class

    def initialize(type, table_name, &block)
      self.table_name = table_name
      self.type = type

      instance_eval &block if block_given?

      if table_name.nil? || type.nil?
        raise ArgumentError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        table_name and type have to be provided. Either as parameters or set within the block.
        MESSAGE
      end

      self.journable_class ||= self.type.gsub(/Journal$/, "")
    end

    def migrate(legacy_journal)
      journal = set_journal(legacy_journal)
      journal_id = journal["id"]

      set_journal_data(journal_id, legacy_journal)
    end

    protected

    def combine_journal(journaled_id, legacy_journal)
      # compute the combined journal from current and all previous changesets.
      combined_journal = legacy_journal["changed_data"]
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
    def migrate_key_value_pairs!(to_insert, legacy_journal, journal_id) end

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

        raise Migration::AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
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
      id, version = legacy_journal["journaled_id"], legacy_journal["version"]

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
          #{quote_value(legacy_journal["id"])},
          #{quote_value(legacy_journal["journaled_id"])},
          #{quote_value(legacy_journal["version"])},
          #{quote_value(legacy_journal["user_id"])},
          #{quote_value(legacy_journal["notes"])},
          #{quote_value(legacy_journal["activity_type"])},
          #{quote_value(legacy_journal["created_at"])},
          #{quote_value(journable_class)}
        );
      SQL

      fetch_journal(legacy_journal)
    end

    def set_journal_data(journal_id, legacy_journal)

      deserialize_journal(legacy_journal)
      journaled_id = legacy_journal["journaled_id"]

      combined_journal = combine_journal(journaled_id, legacy_journal)
      migrate_key_value_pairs!(combined_journal, legacy_journal, journal_id)

      to_insert = insertable_data_journal(combined_journal)

      existing_data_journal = fetch_existing_data_journal(journal_id)

      if existing_data_journal.size > 1

        raise Migration::AmbiguousJournalsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
          It appears there are ambiguous journal data. Please make sure
          journal data are consistent and that the unique constraint on
          journal_id is met.
        MESSAGE

      elsif existing_data_journal.size == 0

        existing_data_journal = create_data_journal(journal_id, to_insert)

      end

      existing_data_journal = existing_data_journal.first

      update_data_journal(existing_data_journal["id"], to_insert)
    end

    def create_data_journal(journal_id, to_insert)
      keys = to_insert.keys
      values = to_insert.values

      db_execute <<-SQL
        INSERT INTO #{journal_table_name} (journal_id#{", " + keys.join(", ") unless keys.empty? })
        VALUES (#{quote_value(journal_id)}#{", " + values.map{|d| quote_value(d)}.join(", ") unless values.empty?});
      SQL

      fetch_existing_data_journal(journal_id)
    end

    def update_data_journal(id, to_insert)
      db_execute <<-SQL unless to_insert.empty?
        UPDATE #{journal_table_name}
           SET #{(to_insert.each.map { |key,value| "#{key} = #{quote_value(value)}"}).join(", ") }
         WHERE id = #{id};
      SQL

    end

    def deserialize_journal(journal)
      integerize_ids(journal)

      journal["changed_data"] = YAML.load(journal["changed_data"])
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
      when "issue_id"
        "work_package_id"
      when "tracker_id"
        "type_id"
      when "end_date"
        "due_date"
      else
        key
      end
    end

    def integerize_ids(journal)
      # turn id fields into integers.
      ["id", "journaled_id", "user_id", "version"].each do |f|
        journal[f] = journal[f].to_i
      end
    end

    def journal_table_name
      quoted_table_name(table_name)
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
