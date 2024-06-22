class AddValidityPeriodToJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :journals, :validity_period, :tstzrange

    reversible do |direction|
      direction.up do
        fix_all_journal_timestamps
        write_validity_period

        add_validity_period_constraint
      end
    end

    add_check_constraint :journals,
                         "NOT isempty(validity_period) AND validity_period IS NOT NULL",
                         name: "journals_validity_period_not_empty"
  end

  def fix_all_journal_timestamps
    max_attempts = attempts = (ENV["MAX_JOURNAL_TIMESTAMPS_ATTEMPTS"].presence && ENV["MAX_JOURNAL_TIMESTAMPS_ATTEMPTS"].to_i) ||
                              Journal.all.maximum(:version)

    invalid_journables = nil

    loop do
      invalid_journables = fix_journal_timestamps(invalid_journables)

      break if invalid_journables.empty?

      if attempts == 0
        raise <<~MSG.squish
          There are still journals with timestamps after their successors timestamp.
          Aborting after #{max_attempts}.
          Run the migration again with the env variable MAX_JOURNAL_TIMESTAMPS_ATTEMPTS set to a higher value.
        MSG
      else
        say "Journals with timestamps after their successors timestamp remain in the database. Retrying..."
      end

      attempts -= 1
    end

    say "All journals' timestamps in the database are correct."
  end

  def fix_journal_timestamps(invalid_journables)
    limit_condition = invalid_journables ? "AND journable_id IN (#{invalid_journables.uniq.join(', ')})" : ""

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

    updated = select_rows <<~SQL.squish
      UPDATE journals
      SET
        created_at = LEAST(journals.created_at, successors.created_at - interval '1  ms'),
        updated_at = CASE
                       WHEN journals.created_at = journals.updated_at
                       THEN LEAST(journals.created_at, successors.created_at - interval '1  ms')
                       ELSE journals.updated_at
                     END

      FROM (
        SELECT
          predecessors.id,
          successors.created_at
        FROM
          journals predecessors
        LEFT JOIN LATERAL (SELECT DISTINCT ON (journable_type, journable_id) *
                           FROM journals successors
                           WHERE successors.version > predecessors.version
                             AND successors.journable_id = predecessors.journable_id
                             AND successors.journable_type = predecessors.journable_type
                             AND successors.created_at <= predecessors.created_at
                           ORDER BY successors.journable_type ASC,
                                    successors.journable_id ASC,
                                    successors.version ASC) successors
        ON successors.journable_id = predecessors.journable_id
        AND successors.journable_type = predecessors.journable_type
      ) successors
      WHERE successors.id = journals.id
      AND successors.created_at <= journals.created_at
      #{limit_condition}
      RETURNING journals.journable_id
    SQL

    updated.flatten
  end

  def write_validity_period
    execute <<~SQL.squish
      UPDATE journals
      SET validity_period = values.validity_period
      FROM (
        SELECT
          predecessors.id,
          tstzrange(predecessors.created_at, successors.created_at) validity_period
        FROM
          journals predecessors
        LEFT JOIN LATERAL (SELECT DISTINCT ON (journable_type, journable_id) *
                           FROM journals successors
                           WHERE successors.version > predecessors.version
                             AND successors.journable_id = predecessors.journable_id
                           ORDER BY successors.journable_type ASC,
                                    successors.journable_id ASC,
                                    successors.version ASC) successors
        ON successors.journable_id = predecessors.journable_id
        AND successors.journable_type = predecessors.journable_type
      ) values
      WHERE values.id = journals.id
    SQL
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
