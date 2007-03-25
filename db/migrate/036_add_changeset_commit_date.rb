class AddChangesetCommitDate < ActiveRecord::Migration
  def self.up
    add_column :changesets, :commit_date, :date, :null => false
    Changeset.update_all "commit_date = committed_on"
  end

  def self.down
    remove_column :changesets, :commit_date
  end
end
