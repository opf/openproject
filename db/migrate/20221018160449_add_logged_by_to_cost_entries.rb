class AddLoggedByToCostEntries < ActiveRecord::Migration[7.0]
  def change
    add_reference :cost_entries, :logged_by, foreign_key: { to_table: :users }, index: true

    reversible do |dir|
      dir.up do
        CostEntry
          .where.not(user_id: User.select(:id))
          .update_all(user_id: DeletedUser.first.id)

        CostEntry.update_all('logged_by_id = user_id')
      end
    end
  end
end
