class AddViewIssuesPermission < ActiveRecord::Migration
  def self.up
    Role.find(:all).each do |r|
      r.add_permission!(:view_issues)
    end
  end

  def self.down
    Role.find(:all).each do |r|
      r.remove_permission!(:view_issues)
    end
  end
end
