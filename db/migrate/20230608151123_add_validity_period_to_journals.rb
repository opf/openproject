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
                         'NOT isempty(validity_period) AND validity_period IS NOT NULL',
                         name: "journals_validity_period_not_empty"
  end

  def fix_all_journal_timestamps
    max_attempts = attempts = ENV['MAX_JOURNAL_TIMESTAMPS_ATTEMPTS'].presence.to_i || Journal.all.maximum(:version)

    loop do
      break if fix_journal_timestamps == 0

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

  def fix_journal_timestamps
    update <<~SQL.squish
      UPDATE journals
      SET
        created_at = LEAST(journals.created_at, values.created_at),
        updated_at = LEAST(journals.updated_at, values.created_at)
      FROM (
        SELECT
          predecessors.id,
          successors.created_at
        FROM
          journals predecessors
        LEFT JOIN LATERAL (SELECT DISTINCT ON (journable_type, journable_id) *
                           FROM "journals"
                           WHERE "journals"."version" > predecessors.version
                             AND "journals"."journable_id" = predecessors.journable_id
                           ORDER BY "journals"."journable_type" ASC,
                                    "journals"."journable_id" ASC,
                                    "journals"."version" ASC) successors
        ON successors.journable_id = predecessors.journable_id
        AND successors.journable_type = predecessors.journable_type
      ) values
      WHERE values.id = journals.id
      AND (values.created_at < journals.created_at OR values.created_at < journals.updated_at)
    SQL
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
                           FROM "journals"
                           WHERE "journals"."version" > predecessors.version
                             AND "journals"."journable_id" = predecessors.journable_id
                           ORDER BY "journals"."journable_type" ASC,
                                    "journals"."journable_id" ASC,
                                    "journals"."version" ASC) successors
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
