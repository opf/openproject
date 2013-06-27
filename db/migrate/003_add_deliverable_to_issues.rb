class AddDeliverableToIssues < ActiveRecord::Migration

  def initialize
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  def self.up
    if @issues_table_exists
      add_column :issues, :deliverable_id, :integer, :null => true
    end
  end

  def self.down
    if @issues_table_exists
      remove_column :issues, :deliverable_id
    end
  end
end
