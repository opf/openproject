class BackfillTimeEntriesWithLoggedById < ActiveRecord::Migration[7.0]
  def change
    TimeEntry.all.update_all('logged_by_id = user_id')
  end
end
