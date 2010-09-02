CostEntry.class_eval do
  generator_for :project, :method => :next_project
  generator_for :user, :method => :next_user
  generator_for :cost_type, :method => :next_cost_type
  generator_for :rate, :method => :next_cost_rate
  generator_for :units, rand(1000)
  generator_for :spent_on, 1.day.ago
  generator_for :comments, "Some comment"
  generator_for :issue, :method => :next_issue
  generator_for :created_on, 1.day.ago
  generator_for :updated_on, Date.today
  generator_for :blocked, false
  generator_for :costs, 20
  generator_for :tyear, 1.day.ago.year
  generator_for :tmonth, 1.day.ago.month
  generator_for :tweek, 1.day.ago.to_date.cweek

  def self.next_project
    Project.last || Project.generate!
  end

  def self.next_cost_rate
    CostRate.last || CostRate.generate!
  end

  def self.next_user
    User.generate_with_protected!
  end

  def self.next_cost_type
    CostType.last || CostType.generate!
  end

  def self.next_issue
    self.next_project.issues.last || Issue.generate_for_project!(next_project)
  end
end
