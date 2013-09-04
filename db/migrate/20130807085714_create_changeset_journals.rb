class CreateChangesetJournals < ActiveRecord::Migration
  def change
    create_table :changeset_journals do |t|
      t.integer  :journal_id,    :null => false
      t.integer  :repository_id, :null => false
      t.string   :revision,      :null => false
      t.string   :committer
      t.datetime :committed_on,  :null => false
      t.text     :comments
      t.date     :commit_date
      t.string   :scmid
      t.integer  :user_id
    end
  end
end
