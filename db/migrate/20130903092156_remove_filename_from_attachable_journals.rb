class RemoveFilenameFromAttachableJournals < ActiveRecord::Migration
  def up
    remove_column :attachable_journals, :filename
  end

  def down
    add_column :attachable_journals, :filename, :string, :default => "", :null => false
  end
end
