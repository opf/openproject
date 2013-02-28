class AddSummaryToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :summary, :text
  end

  def self.down
    remove_column :projects, :summary
  end
end
