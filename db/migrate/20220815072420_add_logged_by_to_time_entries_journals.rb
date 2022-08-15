class AddLoggedByToTimeEntriesJournals < ActiveRecord::Migration[7.0]
  def change
    add_reference :time_entry_journals, :logged_by, foreign_key: { to_table: :users }, index: true

    reversible do |change|
      change.up do
        Journal::TimeEntryJournal
          .where.not(user_id: User.select(:id))
          .update_all(user_id: DeletedUser.first.id)

        execute <<~SQL.squish
          UPDATE time_entry_journals
          SET logged_by_id = user_id
        SQL
      end
    end

    change_column_null :time_entries, :logged_by_id, false
    change_column_null :time_entry_journals, :logged_by_id, false
  end
end
