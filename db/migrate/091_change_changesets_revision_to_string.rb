class ChangeChangesetsRevisionToString < ActiveRecord::Migration
  def self.up
    change_column :changesets, :revision, :string, :null => false
  end

  def self.down
    change_column :changesets, :revision, :integer, :null => false
  end
end
