class LaborBudgetItem < ActiveRecord::Base
  belongs_to :cost_object
  belongs_to :user

  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates_presence_of :user
  
  def costs
    self.budget || self.calculated_costs
  end
  
  def calculated_costs(fixed_date = cost_object.fixed_date, project_id = cost_object.project_id)
    if user && hours && rate = user.rate_at(fixed_date, project_id)
      rate.rate * hours
    else 
      0.0
    end
  end
  
  def can_view_costs?(usr, project)
    usr.allowed_to?(:view_hourly_rates, project, :for => user)
  end
end