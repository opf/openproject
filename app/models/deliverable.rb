# A Deliverable is an item that is created as part of the project.  These items
# contain a collection of issues.
class Deliverable < ActiveRecord::Base
  unloadable
  validates_presence_of :subject
  
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :project
  has_many :issues
  
  acts_as_event :title => Proc.new {|o| "#{l(:label_deliverable)} ##{o.id}: #{o.subject}"},
                :url => Proc.new {|o| {:controller => 'deliverables', :action => 'show', :id => o.id}}                
  
  acts_as_activity_provider :find_options => {:include => [:project, :author]},
                            :timestamp => "#{table_name}.updated_on",
                            :author_key => :author_id
                            
  def copy_from(arg)
    deliverable = arg.is_a?(Deliverable) ? arg : Deliverable.find(arg)
    self.attributes = deliverable.attributes.dup
  end


  # Wrap type column to make it usable in views (especially in a select tag)
  def kind
    self[:type]
  end
  
  def kind=(type)
    self[:type] = type
  end
  
  # Assign all the issues with +version_id+ to this Deliverable
  def assign_issues_by_version(version_id)
    version = Version.find_by_id(version_id)
    return 0 if version.nil? || version.fixed_issues.blank?
    
    version.fixed_issues.each do |issue|
      issue.update_attribute(:deliverable_id, self.id)
    end
    
    return version.fixed_issues.size
  end
  
  # Change the Deliverable type to another type. Valid types are
  #
  # * FixedDeliverable
  # * CostBasedDeliverable
  def change_type(to)
    if [FixedDeliverable.name, CostBasedDeliverable.name].include?(to)
      self.type = to
      self.save!
      return Deliverable.find(self.id)
    else
      return self
    end
  end
  
  # Adjusted score to show the status of the Deliverable.  Will range from 100
  # (everything done with no money spent) to -100 (nothing done, all the money spent)
  def score
    return self.progress - self.budget_ratio
  end
  
  # Amount spent.  Virtual accessor that is overriden by subclasses.
  def spent
    0 
  end
  
  # Budget of labor.  Virtual accessor that is overriden by subclasses.
  def labor_budget
    0
  end
  
  # Budget of materials, i.e. all costs besides labor costs.  Virtual accessor that is overriden by subclasses.
  def materials_budget
    0
  end
  
  def status
    "TODO"
  end
  
  # Label of the current type for display in GUI.  Virtual accessor that is overriden by subclasses.
  def type_label
    return l(:label_deliverable)
  end
  
  
  # Percentage of the deliverable that is complete based on the progress of the
  # assigned issues.
  # TODO:  collect issues based on costs AND estimated_hours
  def progress
    return 0 unless self.issues.size > 0
    
    total ||=  self.issues.collect(&:estimated_hours).compact.sum || 0

    return 0 unless total > 0
    balance = 0.0

    self.issues.each do |issue|
      if use_issue_status_for_done_ratios?
        balance += issue.status.default_done_ratio * issue.estimated_hours unless issue.estimated_hours.nil?
      else
        balance += issue.done_ratio * issue.estimated_hours unless issue.estimated_hours.nil?
      end
    end

    return (balance / total).round
  end
  
  # Amount of the budget spent.  Expressed as as a percentage whole number
  def budget_ratio
    return 0.0 if self.budget.nil? || self.budget == 0.0
    return ((self.spent / self.budget) * 100).round
  end
  
  def css_classes
    return "issue"
  end
  
  def use_issue_status_for_done_ratios?
    return defined?(Setting.issue_status_for_done_ratio?) && Setting.issue_status_for_done_ratio?
  end
  
  
end