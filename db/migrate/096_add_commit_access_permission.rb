class AddCommitAccessPermission < ActiveRecord::Migration

  def self.up
	Role.find(:all).select { |r| not r.builtin? }.each do |r|
	     r.add_permission!(:commit_access)
  	end
  end

  def self.down
	Role.find(:all).select { |r| not r.builtin? }.each do |r|
	     r.remove_permission!(:commit_access)
  	end
  end
end
