class CostBasedDeliverable < Deliverable
  has_many :deliverable_costs, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  has_many :deliverable_hours, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  
  validates_associated :deliverable_costs
  validates_associated :deliverable_hours
  
  # Label of the current deliverable type for display in GUI.
  def type_label
    return l(:label_cost_based_deliverable)
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
      deliverable_hours.build(attributes) if attributes[:hours].to_i > 0
    end
  end
  
  def existing_deliverable_hour_attributes=(deliverable_hour_attributes)
    deliverable_hours.reject(&:new_record?).each do |deliverable_hour|
      attributes = deliverable_hour_attributes[deliverable_hour.id.to_s]
      if attributes && attributes[:hours].to_i > 0
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