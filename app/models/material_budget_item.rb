class MaterialBudgetItem < ActiveRecord::Base
  belongs_to :cost_object
  belongs_to :cost_type
  
  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates_presence_of :cost_type
  
  def costs
    self.budget || self.calculated_costs
  end
  
  def calculated_costs(fixed_date = cost_object.fixed_date)
    if units && cost_type && rate = cost_type.rate_at(fixed_date)
      rate.rate * units
    else
      0.0
    end
  end
end