require_relative './20200924085508_cleanup_orphaned_journal_data'

class AggregateJournals < ActiveRecord::Migration[6.1]
  def up
    [Attachment,
     Changeset,
     Message,
     News,
     WikiContent,
     WorkPackage].each do |klass|
      say_with_time "Aggregating journals for #{klass}" do
        aggregate_journals(klass)
      end
    end

    # Now cleanup all orphaned attachable/customizable journals
    CleanupOrphanedJournalData.up
  end

  # The change is irreversible (aggregated journals cannot be broken down) but down will not cause database inconsistencies.

  def aggregate_journals(klass)
    klass.in_batches(of: 20) do |instances|
      # Instantiating is faster than calculating the aggregated journals multiple times.
      aggregated_journals = aggregated_journals_of(klass, instances).to_a

      aggregated_journals
        .reject { |journal| journal.notes_id == journal.id }
        .each do |mismatched_journal|
        update_journal_notes(mismatched_journal)
      end

      remove_unnecessary_journals(klass, instances, aggregated_journals)
    end
  end

  def aggregated_journals_of(klass, instances)
    Journal
      .aggregated_journal(sql: Journal.where(journable_type: klass.name,
                                             journable_id: instances.pluck(:id))
                                      .to_sql)
  end

  def update_journal_notes(mismatched_journal)
    sql = <<~SQL
      UPDATE journals
      SET notes = :notes
      WHERE id = :id
    SQL

    suppress_messages do
      execute ::OpenProject::SqlSanitization.sanitize(sql, notes: mismatched_journal.notes, id: mismatched_journal.id)
    end
  end

  def remove_unnecessary_journals(klass, instances, aggregated_journals)
    # Only delete the journals (without callbacks as it is faster).
    # We remove the then orphaned attachable/customizable journals later.
    Journal
      .where(journable_type: klass.name, journable_id: instances.pluck(:id))
      .where.not(id: aggregated_journals.map(&:id))
      .delete_all
  end
end
