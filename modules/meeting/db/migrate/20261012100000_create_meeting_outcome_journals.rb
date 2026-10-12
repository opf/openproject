# frozen_string_literal: true

class CreateMeetingOutcomeJournals < ActiveRecord::Migration[8.1]
  def up
    create_table :meeting_outcome_journals do |t|
      t.integer :journal_id, null: false
      t.bigint :outcome_id, null: false
      t.bigint :meeting_agenda_item_id
      t.bigint :work_package_id
      t.integer :kind, null: false
      t.text :notes
    end

    add_index :meeting_outcome_journals,
              %i[journal_id outcome_id],
              unique: true,
              name: :idx_meeting_outcome_journals_journal_outcome

    backfill_outcome_journals
  end

  def down
    drop_table :meeting_outcome_journals
  end

  private

  # Historic values are unknown, so every journal gets the current values of the outcomes created before the journal
  # was superseded. An outcome is only recorded in journals that also record its agenda item.
  def backfill_outcome_journals
    execute(<<~SQL.squish)
      INSERT INTO meeting_outcome_journals
        (journal_id, outcome_id, meeting_agenda_item_id, work_package_id, kind, notes)
      SELECT
        journals.id,
        meeting_outcomes.id,
        meeting_outcomes.meeting_agenda_item_id,
        meeting_outcomes.work_package_id,
        meeting_outcomes.kind,
        meeting_outcomes.notes
      FROM journals
      JOIN meeting_agenda_item_journals ON meeting_agenda_item_journals.journal_id = journals.id
      JOIN meeting_outcomes ON meeting_outcomes.meeting_agenda_item_id = meeting_agenda_item_journals.agenda_item_id
      WHERE journals.journable_type = 'Meeting'
        AND meeting_outcomes.created_at < COALESCE(upper(journals.validity_period), 'infinity')
    SQL
  end
end
