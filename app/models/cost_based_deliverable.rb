class CostBasedDeliverable < Deliverable
  has_many :deliverable_costs, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  has_many :deliverable_hours, :include => :rate, :foreign_key => 'deliverable_id', :dependent => :destroy
  
  validates_associated :deliverable_costs
  validates_associated :deliverable_hours
  
  # Label of the current deliverable type for display in GUI.
  def type_label
    return l(:label_cost_based_deliverable)
  end
  
  def new_deliverable_costs_attributes=(deliverable_costs_attributes)
    deliverable_costs_attributes.each do |attributes|
      deliverable_costs.build(attributes)
    end
  end
  
  def existing_deliverable_costs_attributes=(deliverable_costs_attributes)
    deliverable_costs.reject(&:new_record?).each do |deliverable_cost|
      attributes = deliverable_costs_attributes[deliverable_cost.id.to_s]
      if attributes
        deliverable_cost.attributes = attributes
      else
        deliverable_costs.destroy(deliverable_cost)
      end
    end
  end
  
  def save_deliverable_costs
    deliverable_cost.each do |deliverable_cost|
      deliverable_cost.save(false)
    end
  end
end