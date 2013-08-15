class RenameViewIssuesPermissionToViewWorkPackages < ActiveRecord::Migration
  def self.up
    Role.find(:all).each do |r|
      r.permissions.include? :view_issues
      r.remove_permission!(:view_issues)
      r.add_permission!(:view_work_packages)
    end
  end

  def self.down
    Role.find(:all).each do |r|
      r.permissions.include? :view_work_packages
      r.remove_permission!(:view_work_packages)
      r.add_permission!(:view_issues)
    end
  end
end
