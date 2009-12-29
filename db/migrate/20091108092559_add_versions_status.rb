class AddVersionsStatus < ActiveRecord::Migration
  def self.up
    add_column :versions, :status, :string, :default => 'open'
    Version.update_all("status = 'open'")
  end

  def self.down
    remove_column :versions, :status
  end
end
