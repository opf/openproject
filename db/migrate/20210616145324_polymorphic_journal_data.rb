class PolymorphicJournalData < ActiveRecord::Migration[6.1]
  def up
    add_reference :journals, :data, polymorphic: true, index: true

    [::Journal::ChangesetJournal,
     ::Journal::AttachmentJournal,
     ::Journal::MessageJournal,
     ::Journal::NewsJournal,
     ::Journal::WikiContentJournal,
     ::Journal::WorkPackageJournal,
     ::Journal::BudgetJournal,
     ::Journal::TimeEntryJournal,
     ::Journal::DocumentJournal,
     ::Journal::MeetingJournal,
     ::Journal::MeetingContentJournal].each do |journal_data|
      execute <<~SQL
        UPDATE journals
        SET data_id = data.id, data_type = '#{journal_data.name}'
        FROM #{journal_data.table_name} data
        WHERE data.journal_id = journals.id
      SQL

      remove_column journal_data.table_name, :journal_id
    end
  end

  def down
    [::Journal::ChangesetJournal,
     ::Journal::AttachmentJournal,
     ::Journal::MessageJournal,
     ::Journal::NewsJournal,
     ::Journal::WikiContentJournal,
     ::Journal::WorkPackageJournal,
     ::Journal::BudgetJournal,
     ::Journal::TimeEntryJournal,
     ::Journal::DocumentJournal,
     ::Journal::MeetingJournal,
     ::Journal::MeetingContentJournal].each do |journal_data|
      add_column journal_data.table_name, :journal_id, :integer, index: true

      execute <<~SQL
        UPDATE #{journal_data.table_name} data
        SET journal_id = journals.id
        FROM journals
        WHERE data.id = journals.data_id AND journals.data_type = '#{journal_data.name}'
      SQL
    end

    remove_reference :journals, :data
  end
end
