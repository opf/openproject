class CostEntry < ActiveRecord::Base
  unloadable

  belongs_to :project
  belongs_to :issue
  belongs_to :user
  belongs_to :cost_type
  belongs_to :cost_object
  belongs_to :rate, :class_name => "CostRate"
  
  attr_protected :project_id, :costs, :rate_id
  
  validates_presence_of :project_id, :user_id, :cost_type_id, :units, :spent_on
  validates_numericality_of :units, :allow_nil => false, :message => :activerecord_error_invalid
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  
  named_scope :visible, lambda{|*args|
    { :include => [:project, :user],
      :conditions => (args.first || User.current).allowed_for(:view_cost_entries, args[1])
    }
  }
  
  named_scope :visible_costs, lambda{|*args|
    view_cost_rates = (args.first || User.current).allowed_for(:view_cost_rates, args[1])
    view_cost_entries = (args.first || User.current).allowed_for(:view_cost_entries, args[1])

    { :include => [:project, :user],
      :conditions => [view_cost_entries, view_cost_rates].join(" AND ")
    }
  }
  
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
    
    errors.add :user_id, :activerecord_error_invalid unless User.current.allowed_to? :log_costs, project, :for => user
    begin
      spent_on.to_date
    rescue Exception
      errors.add :spent_on, :activerecord_error_invalid
    end
  end
  
  def before_save
    self.spent_on &&= spent_on.to_date
    update_costs
  end
  
  def overwritten_costs=(costs)
    write_attribute(:overwritten_costs, CostRate.clean_currency(costs))
  end
  
  def units=(units)
    write_attribute(:units, CostRate.clean_currency(units))
  end
  
  
  
  # tyear, tmonth, tweek assigned where setting spent_on attributes
  # these attributes make time aggregations easier
  def spent_on=(date)
    super
    self.tyear = spent_on ? spent_on.year : nil
    self.tmonth = spent_on ? spent_on.month : nil
    self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
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
  end
  
  def update_costs!(rate_attr = nil)
    self.update_costs(rate_attr)
    self.save!
  end
  
  def current_rate
    self.cost_type.rate_at(self.spent_on)
  end
  
    
  # Returns true if the cost entry can be edited by usr, otherwise false
  def editable_by?(usr)
    # FIXME 111 THIS IS A BAAAAAAAAD HACK !!! Fix the loading of Project
    usr.allowed_to?(:edit_cost_entries, Project.find(project_id), :for => user)
  end
  
  # Returns true if the time entry can be edited by usr, otherwise false
  def visible_by?(usr)
    usr.allowed_to?(:view_cost_entries, project, :for => user)
  end
  
  def costs_visible_by?(usr)
    usr.allowed_to?(:view_cost_rates, project, :for => user) || (usr == user && !overridden_costs.nil?)
  end
  
  def self.visible_by(usr)
    with_scope(:find => { :conditions => usr.allowed_for(:view_cost_entries), :include => [:project, :user]}) do
      yield
    end
  end
end