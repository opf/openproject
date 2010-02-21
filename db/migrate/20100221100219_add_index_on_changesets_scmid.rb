class AddIndexOnChangesetsScmid < ActiveRecord::Migration
  def self.up
    add_index :changesets, [:repository_id, :scmid], :name => :changesets_repos_scmid
  end

  def self.down
    remove_index :changesets, :name => :changesets_repos_scmid
  end
end
