class RemoveEnumerationsOpt < ActiveRecord::Migration
  def self.up
    remove_column :enumerations, :opt
  end

  def self.down
    add_column :enumerations, :opt, :string, :limit => 4, :default => '', :null => false
    Enumeration.update_all("opt = 'IPRI'", "type = 'IssuePriority'")
    Enumeration.update_all("opt = 'DCAT'", "type = 'DocumentCategory'")
    Enumeration.update_all("opt = 'ACTI'", "type = 'TimeEntryActivity'")
  end
end
