class ChangeIssuePositionColumn < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.table_exists? 'issues'
      change_column :issues, :position, :integer, :null => true, :default => nil
    end
  end

  def self.down
    if ActiveRecord::Base.connection.table_exists? 'issues'
      change_column :issues, :position, :integer, :null => false
    end
  end
end
