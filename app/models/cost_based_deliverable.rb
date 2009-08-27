class CostBasedDeliverable < Deliverable
  has_many :deliverable_costs, :include => :cost_type, :foreign_key => 'deliverable_id', :dependent => :destroy
  has_many :deliverable_hours, :include => :user, :foreign_key => 'deliverable_id', :dependent => :destroy
  
  validates_associated :deliverable_costs
  validates_associated :deliverable_hours
  
  after_update :save_deliverable_costs
  after_update :save_deliverable_hours
  
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
  
  def material_budget
    deliverable_costs.inject(0.0) {|sum, d| d.costs + sum}
  end

  def labor_budget
    deliverable_hours.inject(0.0) {|sum,d| sum + d.costs}
  end
  
  def spent
    # FIXME: This is very ineffecient database wise. Try to consolidate the queries
    return @spent if @spent
    
    return 0 unless issues.size > 0
    issues.collect(&:overall_costs).compact.sum
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

      p attributes


      if attributes && attributes[:hours].to_i > 0 && attributes[:user_id].to_i > 0
        deliverable_hour.attributes = attributes
      else
        deliverable_hours.delete(deliverable_hour)
      end
    end
  end
  
  def save_deliverable_hours
    p "---------------------------------- SAVING -----------------------------"

    deliverable_hours.each do |deliverable_hour|
      p deliverable_hour

      deliverable_hour.save(false)
    end
  end
  
  
  
end