class RemoveReplyFromMessageJournalizing < ActiveRecord::Migration[6.1]
  def change
    remove_column :message_journals, :last_reply_id, :integer
    remove_column :message_journals, :replies_count, :integer, default: 0, null: false
  end
end
