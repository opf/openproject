class DoNotAllowNullBacklogIds < ActiveRecord::Migration
  def self.up
    change_column :items, :backlog_id, :integer, :default => 0, :null => false
  end

  def self.down
    # do nothing
  end
end
