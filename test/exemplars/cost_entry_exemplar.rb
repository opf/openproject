class CostEntry < ActiveRecord::Base
  generator_for :project_id, :method => :next_project
  generator_for :user_id, :method => :next_user
  generator_for :cost_type_id, :method => :next_cost_type
  generator_for :units, rand(1000)
  generator_for :spent_on, 1.year.ago
  generator_for :comments, "Some comment"
  generator_for :issue_id, :method => :next_issue
  generator_for :created_on, Date.today
  generator_for :updated_on, Date.today
  generator_for :blocked, false
  generator_for :costs, 20
  generator_for :tyear, Date.today.year
  generator_for :tmonth, Date.today.month
  generator_for :tweek, 12
  
  def self.next_project
    Project.count || Project.generate!.id
  end

  def self.next_user
    AnonymousUser.current.id || AnonymousUser.new.save!.id
  end
  
  def self.next_cost_type
    CostType.generate!.id
  end
  
  def self.next_issue
    Issue.count || Issue.generate!.id
  end
end
