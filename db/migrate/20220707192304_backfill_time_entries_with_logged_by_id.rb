class BackfillTimeEntriesWithLoggedById < ActiveRecord::Migration[7.0]
  def up
    TimeEntry
      .where.not(user_id: User.select(:id))
      .update_all(user_id: DeletedUser.first.id)

    TimeEntry.all.update_all('logged_by_id = user_id')
  end

  def down
    # Nothing to do
  end
end
