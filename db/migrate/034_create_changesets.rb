class CreateChangesets < ActiveRecord::Migration
  def self.up
    create_table :changesets do |t|
      t.column :repository_id, :integer, :null => false
      t.column :revision, :integer, :null => false
      t.column :committer, :string, :limit => 30
      t.column :committed_on, :datetime, :null => false
      t.column :comment, :text
    end
    add_index :changesets, [:repository_id, :revision], :unique => true, :name => :changesets_repos_rev
  end

  def self.down
    drop_table :changesets
  end
end
