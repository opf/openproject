class DeliverableHour < ActiveRecord::Base
  unloadable
  
  belongs_to :deliverable
  belongs_to :user

  validates_length_of :comments, :maximum => 255, :allow_nil => true
  validates_presence_of :user
  
  def costs
    self.budget || self.calculated_costs
  end
  
  def calculated_costs(fixed_date = deliverable.fixed_date, project_id = deliverable.project_id)
    if user && hours && rate = user.rate_at(fixed_date, project_id)
      rate.rate * hours
    else 
      0.0
    end
  end
  
  def can_view_costs?(usr, project)
    usr.allowed_to?(:view_all_rates, project) || (user && usr == user && user.allowed_to?(:view_own_rate, project))
  end
end