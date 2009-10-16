class CostEntry < ActiveRecord::Base
  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :cost_type
  belongs_to :cost_object
  belongs_to :rate, :class_name => "CostRate"
  
  attr_protected :project_id, :costs, :rate_id
  
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
  
  def before_save
    update_costs
    issue.save
  end
  
  def real_costs
    # This methods returns the actual assigned costs of the entry
    self.overridden_costs || self.costs || self.calculated_costs
  end
  
  def calculated_costs(rate_attr = nil)
    rate_attr ||= current_rate
    units * rate_attr.rate
  rescue
    0.0
  end
  
  def update_costs(rate_attr = nil)
    rate_attr ||= current_rate
    if rate_attr.nil?
      self.costs = 0.0
      self.rate = nil
      return
    end

    self.costs = self.calculated_costs(rate_attr)
    self.rate = rate_attr
    
    if self.overridden_costs_changed?
      if self.overridden_costs_was.nil?
        # just started to overwrite the cost
        delta = self.costs_was.nil? ? self.overridden_costs : self.overridden_costs - self.costs_was
      elsif self.overridden_costs.nil?
        # removed the overridden cost, use the calculated cost now
        delta = self.costs - self.overridden_costs_was
      else
        # changed the overridden costs
        delta = self.overridden_costs - self.overridden_costs_was
      end
    elsif self.costs_changed? && self.overridden_costs.nil?
      # we use the calculated costs and it has changed
      delta = self.costs - (self.costs_was || 0.0)
    end
    
    self.issue.material_costs += delta if delta
    
    # save the current rate
    @updated_rate = rate_attr.id
    @updated_units = self.units
  end
  
  def update_costs!(rate_attr = nil)
    self.update_costs(rate_attr)
    self.issue.save!
    self.save!
  end
  
  def current_rate
    self.cost_type.rate_at(self.spent_on)
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
end