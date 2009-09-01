class DeliverableCost < ActiveRecord::Base
  belongs_to :deliverable
  belongs_to :cost_type
  
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  
  def costs
    self.budget || self.calculated_costs
  end
  
  def calculated_costs
    units && cost_type ? cost_type.rate_at(deliverable.fixed_date).rate * units : 0.0
  end
end