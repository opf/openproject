class Journal < ActiveRecord::Base
  generator_for :journalized, :method => :generate_issue
  generator_for :user, :method => :generate_user

  def self.generate_issue
    project = Project.generate!
    Issue.generate_for_project!(project)
  end

  def self.generate_user
    User.generate_with_protected!
  end
end
