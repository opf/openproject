class AddChangesetsScmid < ActiveRecord::Migration
  def self.up
    add_column :changesets, :scmid, :string
  end

  def self.down
    remove_column :changesets, :scmid
  end
end
