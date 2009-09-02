class CostEntry < ActiveRecord::Base
  # unloadable
  
  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :cost_type
  belongs_to :deliverable
  
  attr_protected :project_id, :cost
  
  validates_presence_of :project_id, :issue_id, :user_id, :cost_type_id, :units, :spent_on, :issue
  validates_numericality_of :units, :allow_nil => false, :message => :activerecord_error_invalid
  validates_length_of :comments, :maximum => 255, :allow_nil => true

  def after_initialize
    if new_record? && self.cost_type.nil?
      if default_cost_type = CostType.default
        self.cost_type_id = default_cost_type.id
      end
    end
  end
  
  def before_validation
    self.project = issue.project if issue && project.nil?
  end
  
  def validate
    errors.add :units, :activerecord_error_invalid if units && (units < 0)
    errors.add :project_id, :activerecord_error_invalid if project.nil?
    errors.add :issue_id, :activerecord_error_invalid if (issue_id && !issue) || (issue && project!=issue.project)
    
    errors.add :user_id, :activerecord_error_invalid unless (user == User.current) || (User.current.allowed_to? :book_costs, project)
  end
  
#  def overridden_costs=(value)
#    self.attributes[:overridden_costs] = value
#  end
  
  def costs
    self.overridden_costs || calculated_costs
  end
  
  def costs=(value)
    self.overridden_costs = value
  end
  
  def calculated_costs
    units * cost_type.rate_at(self.spent_on).rate
  rescue
    0.0
  end
    
  # Returns true if the time entry can be edited by usr, otherwise false
  def editable_by?(usr)
    (usr == user && usr.allowed_to?(:edit_own_cost_entries, project)) || usr.allowed_to?(:edit_cost_entries, project)
  end
  
  def self.visible_by(usr)
    with_scope(:find => { :conditions => Project.allowed_to_condition(usr, :view_cost_entries) }) do
      yield
    end
  end
  
private
  def clean_currency(value)
    if value && value.is_a?(String)
      value = value.strip
      value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_seperator))
      value.gsub(',', '.')
    else
      value
    end
  end
end
