class AddChangesRevision < ActiveRecord::Migration
  def self.up
    add_column :changes, :revision, :string
  end

  def self.down
    remove_column :changes, :revision
  end
end
