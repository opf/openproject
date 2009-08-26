class CostBasedDeliverable < Deliverable
  has_many :deliverable_costs, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  has_many :deliverable_hours, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  
  validates_associated :deliverable_costs
  validates_associated :deliverable_hours
  
  def before_save
    # set budget to correct value
    self.budget = deliverable_hours.inject(0.0) {|sum,d| sum + d.costs} + deliverable_costs.inject(0.0) {|sum, d| d.costs + sum}
  end
  
  def copy_from(arg)
    deliverable = arg.is_a?(CostBasedDeliverable) ? arg : CostBasedDeliverable.find(arg)
    self.attributes = deliverable.attributes.dup
    self.deliverable_costs = deliverable.deliverable_costs.collect {|v| v.clone}
    self.deliverable_hours = deliverable.deliverable_hours.collect {|v| v.clone}
  end
  
  # Label of the current deliverable type for display in GUI.
  def type_label
    return l(:label_cost_based_deliverable)
  end
  
  def materials_budget
    if User.current.allowed_to?(:view_unit_price, project)
      deliverable_costs.inject(0.0) {|sum, d| d.costs + sum}
    else
      nil
    end
  end

  def labor_budget
    if User.current.allowed_to?(:view_all_rates, project)
      deliverable_hours.inject(0.0) {|sum,d| sum + d.costs}
    else
      nil
    end
  end
  
  def new_deliverable_cost_attributes=(deliverable_cost_attributes)
    deliverable_cost_attributes.each do |index, attributes|
      deliverable_costs.build(attributes) if attributes[:units].to_i > 0
    end
  end
  
  def existing_deliverable_cost_attributes=(deliverable_cost_attributes)
    deliverable_costs.reject(&:new_record?).each do |deliverable_cost|
      attributes = deliverable_cost_attributes[deliverable_cost.id.to_s]
      if attributes && attributes[:units].to_i > 0
        deliverable_cost.attributes = attributes
      else
        deliverable_costs.delete(deliverable_cost)
      end
    end
  end
  
  def save_deliverable_costs
    deliverable_costs.each do |deliverable_cost|
      deliverable_cost.save(false)
    end
  end
  
  def new_deliverable_hour_attributes=(deliverable_hour_attributes)
    deliverable_hour_attributes.each do |index, attributes|
      deliverable_hours.build(attributes) if attributes[:hours].to_i > 0 && attributes[:user_id].to_i > 0
    end
  end
  
  def existing_deliverable_hour_attributes=(deliverable_hour_attributes)
    deliverable_hours.reject(&:new_record?).each do |deliverable_hour|
      attributes = deliverable_hour_attributes[deliverable_hour.id.to_s]
      if attributes && attributes[:hours].to_i > 0 && attributes[:user_id].to_i > 0
        deliverable_hour.attributes = attributes
      else
        deliverable_hours.delete(deliverable_hour)
      end
    end
  end
  
  def save_deliverable_hours
    deliverable_hours.each do |deliverable_hour|
      deliverable_hour.save(false)
    end
  end
  
  
  
end