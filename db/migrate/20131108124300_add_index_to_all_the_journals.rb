class AddIndexToAllTheJournals < ActiveRecord::Migration
  def change
    add_index "attachment_journals", ["journal_id"]
    add_index "changeset_journals", ["journal_id"]
    add_index "message_journals", ["journal_id"]
    add_index "news_journals", ["journal_id"]
    add_index "time_entry_journals", ["journal_id"]
    add_index "wiki_content_journals", ["journal_id"]
    add_index "work_package_journals", ["journal_id"]
  end
end
