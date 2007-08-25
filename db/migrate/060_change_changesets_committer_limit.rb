class ChangeChangesetsCommitterLimit < ActiveRecord::Migration
  def self.up
    change_column :changesets, :committer, :string
  end

  def self.down
    change_column :changesets, :committer, :string, :limit => 30
  end
end
