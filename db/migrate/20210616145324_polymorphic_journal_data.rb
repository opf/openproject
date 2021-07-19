class PolymorphicJournalData < ActiveRecord::Migration[6.1]
  def up
    # For performance reasons, the existing indices are first removed and then readded after the
    # update is done.
    add_data_and_remove_index

    data_journals.each do |journal_data|
      execute <<~SQL
        UPDATE journals
        SET data_id = data.id, data_type = '#{journal_data.name}'
        FROM #{journal_data.table_name} data
        WHERE data.journal_id = journals.id
      SQL

      remove_column journal_data.table_name, :journal_id
    end

    add_indices
  end

  def down
    data_journals.each do |journal_data|
      add_column journal_data.table_name, :journal_id, :integer, index: true

      execute <<~SQL
        UPDATE #{journal_data.table_name} data
        SET journal_id = journals.id
        FROM journals
        WHERE data.id = journals.data_id AND journals.data_type = '#{journal_data.name}'
      SQL
    end

    remove_reference :journals, :data, polymorphic: true
  end

  def data_journals
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
     ::Journal::MeetingContentJournal]
  end

  def add_data_and_remove_index
    change_table :journals do |j|
      j.references :data, polymorphic: true, index: false

      j.remove_index :journable_id
      j.remove_index :journable_type
      j.remove_index :created_at
      j.remove_index :user_id
      j.remove_index :activity_type
      j.remove_index %i[journable_type journable_id version]
    end
  end

  def add_indices
    change_table :journals do |j|
      j.index :journable_id
      j.index :journable_type
      j.index :created_at
      j.index :user_id
      j.index :activity_type
      j.index %i[journable_type journable_id version], unique: true
      j.index %i[data_id data_type], unique: true
    end
  end
end
