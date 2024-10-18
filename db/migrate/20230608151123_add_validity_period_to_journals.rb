class AddValidityPeriodToJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :journals, :validity_period, :tstzrange

    reversible do |direction|
      direction.up do
        create_successor_journals_utility_table

        fix_all_journal_timestamps
        write_validity_period

        drop_successor_journals_utility_table

        add_validity_period_constraint
      end
    end

    add_check_constraint :journals,
                         "NOT isempty(validity_period) AND validity_period IS NOT NULL",
                         name: "journals_validity_period_not_empty"
  end

  def fix_all_journal_timestamps
    return unless current_max_journal_version

    say "Fixing potential timestamp inconsistencies on existing journals."

    current_max_journal_version.downto(1).each do |version|
      say_with_time "Fixing timestamps for journals with version #{version}." do
        fixed_journals = fix_journal_timestamps(version)

        say "Fixed timestamps for #{fixed_journals.cmdtuples} journals.", true if fixed_journals.cmdtuples.positive?
      end
    end

    say "Done."
  end

  def create_successor_journals_utility_table
    say_with_time "Creating utility table to improve the performance of subsequent actions." do
      suppress_messages do
        create_table :successor_journals, id: false do |t|
          t.references :predecessor, null: true, index: false
          t.references :successor, null: true, index: false
        end

        execute <<~SQL.squish
          INSERT INTO
            successor_journals
          SELECT
            predecessors.id predecessor_id,
            successors.id successor_id
          FROM
            journals predecessors
          LEFT JOIN LATERAL (SELECT DISTINCT ON (journable_type, journable_id) *
                              FROM journals successors
                              WHERE successors.version > predecessors.version
                                AND successors.journable_id = predecessors.journable_id
                                AND successors.journable_type = predecessors.journable_type
                              ORDER BY successors.journable_type ASC,
                                      successors.journable_id ASC,
                                      successors.version ASC) successors
          ON successors.journable_id = predecessors.journable_id
          AND successors.journable_type = predecessors.journable_type
        SQL

        add_index :successor_journals, :predecessor_id
        add_index :successor_journals, :successor_id
      end
    end
  end

  def drop_successor_journals_utility_table
    suppress_messages do
      drop_table :successor_journals
    end
  end

  def current_max_journal_version
    @current_max_journal_version ||= suppress_messages { select_one("SELECT MAX(version) FROM journals")["max"] }
  end

  # Update journals with their timestamps after the timestamp of their successor
  # (as identified by the journal belonging to the same journable and having the smallest version
  # larger than the journal's).
  # If one such is found, the:
  # * created_at is set to be the minimum of the journal's and the successor's created_at. But of the successor's value some
  #   small amount needs to be subtracted as later on the validity_period is calculated as a range from the predecessor's
  #   created_at to the successor's created_at. If the two values would be equal, the range would be empty
  #   resulting in an error.
  # * updated_at is only altered if created_at and updated_at are equal, meaning the journal has never been updated.
  #   A journal might very well be updated after its successor was created, because as a note can be updated
  #   by the user at anytime.
  #   This might have the consequence of the updated_at wrongfully being after the created_at of the successor,
  #   but this will not be invalid.
  def fix_journal_timestamps(version)
    suppress_messages do
      execute <<~SQL.squish
        UPDATE journals
        SET
          created_at = LEAST(journals.created_at, successors.created_at - INTERVAL '1ms'),
          updated_at = CASE
                         WHEN journals.created_at = journals.updated_at
                         THEN LEAST(journals.created_at, successors.created_at - INTERVAL '1ms')
                         ELSE journals.updated_at
                       END
        FROM successor_journals, journals successors
        WHERE successor_journals.predecessor_id = journals.id AND successor_journals.successor_id = successors.id
        AND successors.created_at <= journals.created_at
        AND journals.version = #{version}
      SQL
    end
  end

  def write_validity_period
    say_with_time "Writing validity periods for journals." do
      suppress_messages do
        execute <<~SQL.squish
          UPDATE journals
          SET validity_period = values.validity_period
          FROM (
            SELECT
              predecessors.id,
              tstzrange(predecessors.created_at, successors.created_at) validity_period
            FROM
              journals predecessors
            LEFT JOIN successor_journals
            ON successor_journals.predecessor_id = predecessors.id
            LEFT JOIN journals successors
            ON successor_journals.successor_id = successors.id
          ) values
          WHERE values.id = journals.id
        SQL
      end
    end

    say "Done."
  end

  def add_validity_period_constraint
    execute <<~SQL.squish
      CREATE EXTENSION IF NOT EXISTS btree_gist;

      ALTER TABLE journals
      ADD CONSTRAINT non_overlapping_journals_validity_periods
      EXCLUDE USING gist (journable_id WITH =, journable_type WITH =, validity_period WITH &&)
      DEFERRABLE
    SQL
  end
end
